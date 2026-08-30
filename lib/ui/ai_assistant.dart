import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ai/finance_ai.dart';
import '../ai/gemini_service.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'ai_settings.dart';
import 'common.dart';

enum _AiMode { chat, transaction }

class _ChatMessage {
  final bool user;
  final String text;
  final AiTransactionSuggestion? suggestion;
  bool handled = false;

  _ChatMessage({
    required this.user,
    required this.text,
    this.suggestion,
  });
}

class FinoraAiScreen extends StatefulWidget {
  const FinoraAiScreen({super.key});

  @override
  State<FinoraAiScreen> createState() => _FinoraAiScreenState();
}

class _FinoraAiScreenState extends State<FinoraAiScreen> {
  final _gemini = const GeminiService();
  final _ai = const FinoraAiService();
  final _composer = TextEditingController();
  final _keyController = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  final _messages = <_ChatMessage>[
    _ChatMessage(
      user: false,
      text:
          'Oi! Eu sou o Finora IA. Posso analisar seus números, responder perguntas e preparar lançamentos para você confirmar.',
    ),
  ];

  bool _checkingKey = true;
  bool _hasKey = false;
  bool _busy = false;
  bool _busyKey = false;
  bool _obscureKey = true;
  _AiMode _mode = _AiMode.chat;

  @override
  void initState() {
    super.initState();
    _refreshKey();
  }

  @override
  void dispose() {
    _composer.dispose();
    _keyController.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _refreshKey() async {
    final value = await _gemini.hasApiKey();
    if (!mounted) return;
    setState(() {
      _hasKey = value;
      _checkingKey = false;
    });
  }

  Future<void> _connectKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      _snack('Cole sua chave do Gemini para conectar.');
      return;
    }
    setState(() => _busyKey = true);
    try {
      await _gemini.validateApiKey(key);
      await _gemini.saveApiKey(key);
      if (!mounted) return;
      _keyController.clear();
      setState(() {
        _hasKey = true;
        _messages.add(
          _ChatMessage(
            user: false,
            text:
                'Conectado. Agora é só conversar comigo ou trocar para Lançar quando quiser registrar algo.',
          ),
        );
      });
      _scrollToEnd();
    } on GeminiApiException catch (error) {
      _snack(error.message);
    } finally {
      if (mounted) setState(() => _busyKey = false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      PremiumRoute(page: const AiSettingsScreen()),
    );
    await _refreshKey();
  }

  String _conversationContext() {
    final messages = _messages
        .where((message) => message.suggestion == null)
        .toList(growable: false);
    final start = messages.length > 8 ? messages.length - 8 : 0;
    return messages
        .sublist(start)
        .map((message) => '${message.user ? 'Usuário' : 'Finora'}: ${message.text}')
        .join('\n');
  }

  Future<void> _send([String? preset]) async {
    if (_busy || !_hasKey) return;
    final clean = (preset ?? _composer.text).trim();
    if (clean.isEmpty) return;

    final history = _conversationContext();
    final mode = _mode;
    setState(() {
      _messages.add(_ChatMessage(user: true, text: clean));
      _composer.clear();
      _busy = true;
    });
    _scrollToEnd();

    try {
      if (mode == _AiMode.transaction) {
        final suggestion = await _ai.interpretTransaction(
          context.read<FinanceStore>(),
          clean,
        );
        if (!mounted) return;
        setState(
          () => _messages.add(
            _ChatMessage(
              user: false,
              text: 'Entendi. Confira antes de registrar:',
              suggestion: suggestion,
            ),
          ),
        );
      } else {
        final question = history.isEmpty
            ? clean
            : '''Use esta conversa recente somente para entender referências e perguntas de continuação:
$history

Pergunta atual: $clean''';
        final answer = await _ai.ask(
          context.read<FinanceStore>(),
          question,
        );
        if (!mounted) return;
        setState(() => _messages.add(_ChatMessage(user: false, text: answer)));
      }
    } on GeminiApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          _ChatMessage(user: false, text: 'Não consegui concluir: ${error.message}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToEnd();
      }
    }
  }

  Future<void> _analyze() async {
    if (_busy || !_hasKey) return;
    setState(() {
      _mode = _AiMode.chat;
      _messages.add(
        _ChatMessage(user: true, text: 'Analise meu mês e destaque o que importa.'),
      );
      _busy = true;
    });
    _scrollToEnd();
    try {
      final answer = await _ai.analyzeSelectedMonth(context.read<FinanceStore>());
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(user: false, text: answer)));
    } on GeminiApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          _ChatMessage(user: false, text: 'Não consegui analisar agora: ${error.message}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToEnd();
      }
    }
  }

  void _askPreset(String text) {
    setState(() => _mode = _AiMode.chat);
    _send(text);
  }

  void _startTransaction() {
    setState(() => _mode = _AiMode.transaction);
    _focus.requestFocus();
  }

  void _confirm(_ChatMessage message) {
    final suggestion = message.suggestion;
    if (suggestion == null || message.handled) return;
    if (!suggestion.apply(context.read<FinanceStore>())) {
      setState(
        () => _messages.add(
          _ChatMessage(
            user: false,
            text:
                'Não consegui validar esse lançamento. Confira se a conta ou cartão ainda existe.',
          ),
        ),
      );
      _scrollToEnd();
      return;
    }
    setState(() {
      message.handled = true;
      _mode = _AiMode.chat;
      _messages.add(
        _ChatMessage(
          user: false,
          text: 'Pronto — lançamento registrado e saldos atualizados.',
        ),
      );
    });
    _scrollToEnd();
  }

  void _discard(_ChatMessage message) {
    if (message.handled) return;
    setState(() {
      message.handled = true;
      _messages.add(
        _ChatMessage(user: false, text: 'Tudo bem. Descartei essa sugestão.'),
      );
    });
    _scrollToEnd();
  }

  void _clear() {
    setState(() {
      _messages
        ..clear()
        ..add(
          _ChatMessage(
            user: false,
            text: 'Conversa limpa. O que você quer entender ou registrar agora?',
          ),
        );
      _mode = _AiMode.chat;
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final setup = !_checkingKey && !_hasKey;
    final count = _messages.length + (setup ? 1 : 0) + (_busy ? 1 : 0);

    return Column(
      children: [
        _header(context),
        _quickActions(),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
            itemCount: count,
            itemBuilder: (context, rawIndex) {
              var index = rawIndex;
              if (setup) {
                if (index == 0) return _keySetup(context);
                index--;
              }
              if (index < _messages.length) {
                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MessageBubble(
                    message: message,
                    source: message.suggestion == null
                        ? null
                        : _sourceLabel(message.suggestion!),
                    onConfirm: () => _confirm(message),
                    onDiscard: () => _discard(message),
                  ),
                );
              }
              return const _TypingBubble();
            },
          ),
        ),
        _composerArea(context),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final status = _checkingKey
        ? 'Verificando conexão...'
        : _hasKey
            ? 'Gemini conectado'
            : 'Conecte o Gemini para começar';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 8, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FinoraColors.investment.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: FinoraColors.investment,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finora IA',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasKey ? FinoraColors.income : FinoraColors.warning,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        status,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8.8,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Limpar conversa',
            onPressed: _clear,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Configurações da IA',
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final enabled = _hasKey && !_busy;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 5),
        children: [
          _chip(Icons.analytics_outlined, 'Analisar mês', enabled ? _analyze : null),
          _chip(
            Icons.wallet_outlined,
            'Quanto posso gastar?',
            enabled
                ? () => _askPreset(
                      'Quanto eu posso gastar sem comprometer os próximos pagamentos?',
                    )
                : null,
          ),
          _chip(
            Icons.event_note_rounded,
            'Próximas contas',
            enabled
                ? () => _askPreset(
                      'Quais são meus próximos compromissos e o que merece atenção?',
                    )
                : null,
          ),
          _chip(
            Icons.credit_card_rounded,
            'Cartões',
            enabled
                ? () => _askPreset('Resuma a situação dos meus cartões e faturas.')
                : null,
          ),
          _chip(
            Icons.add_card_rounded,
            'Registrar gasto',
            enabled ? _startTransaction : null,
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, VoidCallback? onTap) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ActionChip(
          avatar: Icon(icon, size: 16),
          label: Text(label),
          onPressed: onTap,
          visualDensity: VisualDensity.compact,
          labelStyle: const TextStyle(fontSize: 9.2, fontWeight: FontWeight.w700),
        ),
      );

  Widget _keySetup(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SurfaceCard(
          borderColor: FinoraColors.investment.withValues(alpha: .30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.key_rounded, color: FinoraColors.investment, size: 21),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Conecte sua chave Gemini aqui',
                      style: TextStyle(fontSize: 12.3, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Você só faz isso uma vez. A chave fica no armazenamento seguro do aparelho e não vai para o GitHub.',
                style: TextStyle(
                  fontSize: 9,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _keyController,
                obscureText: _obscureKey,
                enabled: !_busyKey,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Chave da API Gemini',
                  hintText: 'Cole a chave do Google AI Studio',
                  suffixIcon: IconButton(
                    onPressed: _busyKey
                        ? null
                        : () => setState(() => _obscureKey = !_obscureKey),
                    icon: Icon(
                      _obscureKey
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _busyKey ? null : _connectKey,
                icon: _busyKey
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link_rounded),
                label: Text(_busyKey ? 'Testando conexão...' : 'Testar e conectar'),
              ),
              TextButton(
                onPressed: _busyKey ? null : _openSettings,
                child: const Text('Privacidade e opções avançadas'),
              ),
            ],
          ),
        ),
      );

  Widget _composerArea(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _ModePill(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Conversar',
                    selected: _mode == _AiMode.chat,
                    onTap: () => setState(() => _mode = _AiMode.chat),
                  ),
                  const SizedBox(width: 7),
                  _ModePill(
                    icon: Icons.add_card_rounded,
                    label: 'Lançar',
                    selected: _mode == _AiMode.transaction,
                    onTap: _startTransaction,
                  ),
                  const Spacer(),
                  if (_mode == _AiMode.transaction)
                    Text(
                      'confirmação obrigatória',
                      style: TextStyle(
                        fontSize: 8,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      focusNode: _focus,
                      enabled: _hasKey && !_busy,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: !_hasKey
                            ? 'Conecte o Gemini acima para começar'
                            : _mode == _AiMode.transaction
                                ? 'Ex.: gastei 32,90 de gasolina no Nubank'
                                : 'Pergunte qualquer coisa sobre suas finanças...',
                        prefixIcon: Icon(
                          _mode == _AiMode.transaction
                              ? Icons.edit_note_rounded
                              : Icons.auto_awesome_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: _mode == _AiMode.transaction
                        ? 'Interpretar lançamento'
                        : 'Enviar',
                    onPressed: !_hasKey || _busy ? null : () => _send(),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  String _sourceLabel(AiTransactionSuggestion suggestion) {
    if (suggestion.paymentKind == PaymentKind.card) {
      return context.read<FinanceStore>().findCard(suggestion.cardId)?.name ?? 'Cartão';
    }
    return suggestion.accountName;
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final String? source;
  final VoidCallback onConfirm;
  final VoidCallback onDiscard;

  const _MessageBubble({
    required this.message,
    required this.source,
    required this.onConfirm,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: message.user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.user
                ? FinoraColors.goldBright.withValues(alpha: .14)
                : scheme.surfaceContainerHighest.withValues(alpha: .58),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: message.user
                  ? FinoraColors.goldBright.withValues(alpha: .22)
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!message.user) ...[
                const Text(
                  '✦ FINORA IA',
                  style: TextStyle(
                    fontSize: 7.8,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w900,
                    color: FinoraColors.investment,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              SelectableText(
                message.text,
                style: const TextStyle(fontSize: 10.8, height: 1.48),
              ),
              if (message.suggestion case final suggestion?) ...[
                const SizedBox(height: 10),
                _SuggestionCard(
                  suggestion: suggestion,
                  source: source ?? suggestion.accountName,
                  handled: message.handled,
                  onConfirm: onConfirm,
                  onDiscard: onDiscard,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: .58),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 9),
                Text('Finora está pensando...', style: TextStyle(fontSize: 9.5)),
              ],
            ),
          ),
        ),
      );
}

class _ModePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModePill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: selected
            ? FinoraColors.investment.withValues(alpha: .13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? FinoraColors.investment
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8.8,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? FinoraColors.investment : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SuggestionCard extends StatelessWidget {
  final AiTransactionSuggestion suggestion;
  final String source;
  final bool handled;
  final VoidCallback onConfirm;
  final VoidCallback onDiscard;

  const _SuggestionCard({
    required this.suggestion,
    required this.source,
    required this.handled,
    required this.onConfirm,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final type = switch (suggestion.type) {
      TransactionType.income => 'Receita',
      TransactionType.expense => 'Despesa',
      TransactionType.transfer => 'Transferência',
    };
    final amount =
        'R\$ ${suggestion.amount.toStringAsFixed(2).replaceAll('.', ',')}';
    final date =
        '${suggestion.date.day.toString().padLeft(2, '0')}/${suggestion.date.month.toString().padLeft(2, '0')}/${suggestion.date.year}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinoraColors.investment.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FinoraColors.investment.withValues(alpha: .24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                handled ? Icons.check_circle_rounded : Icons.fact_check_outlined,
                size: 18,
                color: handled ? FinoraColors.income : FinoraColors.investment,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  handled ? 'Sugestão encerrada' : 'Confira antes de registrar',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${(suggestion.confidence * 100).round()}%',
                style: const TextStyle(fontSize: 8.4, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _detail('Tipo', type),
          _detail('Valor', amount),
          _detail('Descrição', suggestion.title),
          _detail('Categoria', suggestion.category),
          _detail('Data', date),
          _detail(suggestion.destinationAccountName == null ? 'Origem' : 'De', source),
          if (suggestion.destinationAccountName != null)
            _detail('Para', suggestion.destinationAccountName!),
          if (suggestion.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              suggestion.reason,
              style: TextStyle(
                fontSize: 8.5,
                height: 1.35,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (!handled) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onDiscard,
                    child: const Text('Descartar'),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 8.2))),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 9.8, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}
