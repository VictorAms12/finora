import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ai/finance_ai.dart';
import '../ai/gemini_service.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'ai_settings.dart';
import 'common.dart';

class FinoraAiScreen extends StatefulWidget {
  const FinoraAiScreen({super.key});

  @override
  State<FinoraAiScreen> createState() => _FinoraAiScreenState();
}

class _FinoraAiScreenState extends State<FinoraAiScreen> {
  final _gemini = const GeminiService();
  final _ai = const FinoraAiService();
  final _quickController = TextEditingController();
  final _questionController = TextEditingController();

  bool _hasKey = false;
  bool _busyQuick = false;
  bool _busyAnalysis = false;
  bool _busyQuestion = false;
  AiTransactionSuggestion? _suggestion;
  String? _analysis;
  String? _answer;

  @override
  void initState() {
    super.initState();
    _refreshKey();
  }

  @override
  void dispose() {
    _quickController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _refreshKey() async {
    final value = await _gemini.hasApiKey();
    if (mounted) setState(() => _hasKey = value);
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      PremiumRoute(page: const AiSettingsScreen()),
    );
    await _refreshKey();
  }

  Future<void> _interpret() async {
    final store = context.read<FinanceStore>();
    setState(() => _busyQuick = true);
    try {
      final result = await _ai.interpretTransaction(store, _quickController.text);
      if (!mounted) return;
      setState(() => _suggestion = result);
    } on GeminiApiException catch (error) {
      _snack(error.message);
    } finally {
      if (mounted) setState(() => _busyQuick = false);
    }
  }

  void _confirmSuggestion() {
    final suggestion = _suggestion;
    if (suggestion == null) return;
    final ok = suggestion.apply(context.read<FinanceStore>());
    if (!ok) {
      _snack('Não foi possível validar esse lançamento. Revise contas e cartões.');
      return;
    }
    _quickController.clear();
    setState(() => _suggestion = null);
    _snack('Lançamento confirmado e registrado.');
  }

  Future<void> _analyze() async {
    setState(() => _busyAnalysis = true);
    try {
      final text = await _ai.analyzeSelectedMonth(context.read<FinanceStore>());
      if (!mounted) return;
      setState(() => _analysis = text);
    } on GeminiApiException catch (error) {
      _snack(error.message);
    } finally {
      if (mounted) setState(() => _busyAnalysis = false);
    }
  }

  Future<void> _ask() async {
    setState(() => _busyQuestion = true);
    try {
      final text = await _ai.ask(
        context.read<FinanceStore>(),
        _questionController.text,
      );
      if (!mounted) return;
      setState(() => _answer = text);
    } on GeminiApiException catch (error) {
      _snack(error.message);
    } finally {
      if (mounted) setState(() => _busyQuestion = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _typeLabel(AiTransactionSuggestion value) => switch (value.type) {
        TransactionType.income => 'Receita',
        TransactionType.expense => 'Despesa',
        TransactionType.transfer => 'Transferência',
      };

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      eyebrow: 'ASSISTENTE FINANCEIRO',
      title: 'Finora IA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_hasKey) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: FinoraColors.investment),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Configure o Gemini para ativar a IA',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A chave fica salva no armazenamento seguro deste aparelho e não é incluída no aplicativo nem no GitHub.',
                    style: TextStyle(fontSize: 9.2, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.key_rounded),
                    label: const Text('Configurar Gemini'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text('LANÇAMENTO RÁPIDO', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Descreva como você falaria normalmente',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ex.: “gastei 47,90 no mercado hoje no Nubank”',
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quickController,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _hasKey && !_busyQuick ? _interpret() : null,
                  decoration: const InputDecoration(
                    hintText: 'O que aconteceu?',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: !_hasKey || _busyQuick ? null : _interpret,
                  icon: _busyQuick
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_busyQuick ? 'Interpretando...' : 'Interpretar'),
                ),
                if (_suggestion case final suggestion?) ...[
                  const SizedBox(height: 14),
                  _SuggestionCard(
                    type: _typeLabel(suggestion),
                    amount: _money(suggestion.amount),
                    title: suggestion.title,
                    category: suggestion.category,
                    date: _date(suggestion.date),
                    source: suggestion.paymentKind == PaymentKind.card
                        ? context
                                .read<FinanceStore>()
                                .findCard(suggestion.cardId)
                                ?.name ??
                            'Cartão'
                        : suggestion.accountName,
                    destination: suggestion.destinationAccountName,
                    confidence: suggestion.confidence,
                    reason: suggestion.reason,
                    onConfirm: _confirmSuggestion,
                    onDiscard: () => setState(() => _suggestion = null),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('ANÁLISE DO MÊS', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Resumo inteligente dos seus próprios números',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'O Finora calcula os números localmente e envia ao Gemini somente um contexto reduzido para explicar tendências e compromissos.',
                  style: TextStyle(fontSize: 9.1, height: 1.45),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: !_hasKey || _busyAnalysis ? null : _analyze,
                  icon: _busyAnalysis
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.analytics_outlined),
                  label: Text(_busyAnalysis ? 'Analisando...' : 'Analisar meu mês'),
                ),
                if (_analysis case final text?) ...[
                  const SizedBox(height: 12),
                  _AiResponse(text: text),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('PERGUNTE AO FINORA', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _questionController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Ex.: Em qual categoria estou gastando mais?',
                    prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: !_hasKey || _busyQuestion ? null : _ask,
                  icon: _busyQuestion
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_busyQuestion ? 'Pensando...' : 'Perguntar'),
                ),
                if (_answer case final text?) ...[
                  const SizedBox(height: 12),
                  _AiResponse(text: text),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Configurações e privacidade da IA'),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String type;
  final String amount;
  final String title;
  final String category;
  final String date;
  final String source;
  final String? destination;
  final double confidence;
  final String reason;
  final VoidCallback onConfirm;
  final VoidCallback onDiscard;

  const _SuggestionCard({
    required this.type,
    required this.amount,
    required this.title,
    required this.category,
    required this.date,
    required this.source,
    required this.destination,
    required this.confidence,
    required this.reason,
    required this.onConfirm,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).round();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: FinoraColors.investment.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FinoraColors.investment.withValues(alpha: .25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: FinoraColors.investment),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Confirme antes de registrar',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                ),
              ),
              Text('$percent%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          _detail('Tipo', type),
          _detail('Valor', amount),
          _detail('Descrição', title),
          _detail('Categoria', category),
          _detail('Data', date),
          _detail(destination == null ? 'Origem' : 'De', source),
          if (destination != null) _detail('Para', destination!),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reason,
              style: TextStyle(
                fontSize: 8.8,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onDiscard,
                  child: const Text('Descartar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Confirmar lançamento'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              child: Text(label, style: const TextStyle(fontSize: 8.5)),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}

class _AiResponse extends StatelessWidget {
  final String text;

  const _AiResponse({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: SelectableText(
          text,
          style: const TextStyle(fontSize: 10, height: 1.55),
        ),
      );
}
