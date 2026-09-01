import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../ai/finance_ai.dart';
import '../ai/gemini_service.dart';
import '../ai/receipt_ai.dart';
import '../intelligence_engine.dart';
import '../models.dart';
import '../notification_service.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

class IntelligenceCenterScreen extends StatefulWidget {
  const IntelligenceCenterScreen({super.key});

  @override
  State<IntelligenceCenterScreen> createState() => _IntelligenceCenterScreenState();
}

class _IntelligenceCenterScreenState extends State<IntelligenceCenterScreen> {
  static const _engine = FinoraIntelligenceEngine();
  static const _receiptAi = ReceiptAiService();
  static const _financeAi = FinoraAiService();

  final _speech = stt.SpeechToText();
  final _voiceController = TextEditingController();

  bool _listening = false;
  bool _processing = false;
  String? _pendingInput;
  String? _clarification;
  List<String> _choices = const [];
  AiTransactionSuggestion? _suggestion;
  ReceiptScanResult? _receipt;

  @override
  void dispose() {
    _speech.cancel();
    _voiceController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == stt.SpeechToText.doneStatus ||
            status == stt.SpeechToText.notListeningStatus) {
          setState(() => _listening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _listening = false);
        _snack('Não consegui usar o microfone: ${error.errorMsg}');
      },
    );
    if (!available) {
      _snack('Reconhecimento de voz não está disponível neste dispositivo.');
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        _voiceController.text = result.recognizedWords;
        _voiceController.selection = TextSelection.collapsed(
          offset: _voiceController.text.length,
        );
        setState(() {});
      },
      listenOptions: const stt.SpeechListenOptions(
        localeId: 'pt_BR',
        partialResults: true,
        cancelOnError: true,
        pauseFor: Duration(seconds: 4),
        listenFor: Duration(seconds: 35),
      ),
    );
  }

  Future<void> _pickReceipt() async {
    if (_processing) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _snack('Não consegui ler o arquivo selecionado.');
      return;
    }
    final extension = (file.extension ?? '').toLowerCase();
    final mime = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    setState(() {
      _processing = true;
      _receipt = null;
      _suggestion = null;
      _clarification = null;
      _choices = const [];
    });
    try {
      final store = context.read<FinanceStore>();
      final result = await _receiptAi.analyze(
        bytes: Uint8List.fromList(bytes),
        mimeType: mime,
        categories: store.expenseCategories,
      );
      if (!mounted) return;
      setState(() {
        _receipt = result;
        _processing = false;
      });
      await _interpret(_receiptInput(result));
    } on GeminiApiException catch (error) {
      _snack(error.message);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String _receiptInput(ReceiptScanResult result) {
    final date = result.date;
    final dateText = date == null
        ? ''
        : ' no dia ${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final payment = result.paymentHint.isEmpty
        ? ''
        : ' O comprovante mostra ${result.paymentHint} como meio de pagamento.';
    return 'Registre uma despesa de R\$ ${result.amount.toStringAsFixed(2)} em ${result.merchant}$dateText. Categoria: ${result.category}.$payment';
  }

  Future<void> _interpret(String raw) async {
    final clean = raw.trim();
    if (clean.isEmpty || _processing) return;
    setState(() {
      _processing = true;
      _suggestion = null;
      _clarification = null;
      _choices = const [];
    });
    try {
      final result = await _financeAi.interpretTransactionConversational(
        context.read<FinanceStore>(),
        clean,
      );
      if (!mounted) return;
      if (result.needsClarification) {
        setState(() {
          _pendingInput = clean;
          _clarification = result.clarification;
          _choices = result.choices;
        });
      } else {
        setState(() {
          _pendingInput = null;
          _suggestion = result.suggestion;
        });
      }
    } on GeminiApiException catch (error) {
      _snack(error.message);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _answerClarification(String answer) async {
    final base = _pendingInput;
    if (base == null) return;
    await _interpret('$base\nResposta complementar do usuário: $answer');
  }

  void _confirmSuggestion() {
    final suggestion = _suggestion;
    if (suggestion == null) return;
    final ok = suggestion.apply(context.read<FinanceStore>());
    if (!ok) {
      _snack('Não consegui registrar. Confira conta/cartão e tente novamente.');
      return;
    }
    setState(() {
      _suggestion = null;
      _receipt = null;
      _pendingInput = null;
      _clarification = null;
      _choices = const [];
      _voiceController.clear();
    });
    _snack('Movimentação registrada e saldos atualizados.');
  }

  void _createRecurring(SubscriptionCandidate item) {
    final store = context.read<FinanceStore>();
    final ok = store.addRecurring(
      type: TransactionType.expense,
      title: item.title,
      category: item.category,
      amount: item.averageAmount,
      sourceName: item.sourceName,
      paymentKind: item.paymentKind,
      cardId: item.cardId,
      frequency: RecurrenceFrequency.monthly,
      startDate: item.nextExpectedDate,
    );
    _snack(
      ok
          ? 'Recorrência criada a partir da próxima cobrança estimada.'
          : 'Não consegui criar a recorrência com esses dados.',
    );
    if (ok) setState(() {});
  }

  Future<void> _testSmartNotification(IntelligenceReport report) async {
    if (report.insights.isEmpty) {
      _snack('Nenhum alerta relevante agora.');
      return;
    }
    final granted = await NotificationService.requestPermissions();
    if (!granted) {
      _snack('Permissão de notificação não foi concedida.');
      return;
    }
    final item = report.insights.first;
    await NotificationService.showSmartInsight(
      title: 'Finora · ${item.title}',
      body: item.message,
    );
    _snack('Alerta inteligente enviado.');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final report = _engine.analyze(store);
    return DefaultTabController(
      length: 3,
      child: PageScaffold(
        eyebrow: 'FINORA INTELLIGENCE',
        title: 'Inteligência',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: FinoraColors.investment.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${report.healthScore}',
                      style: TextStyle(
                        color: FinoraColors.investment,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saúde financeira monitorada',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${report.insights.length} insight(s) · ${report.subscriptions.length} padrão(ões) recorrente(s) · ${report.anomalies.length} anomalia(s)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Testar alerta inteligente',
                    onPressed: () => _testSmartNotification(report),
                    icon: const Icon(Icons.notifications_active_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const TabBar(
              tabs: [
                Tab(text: 'Insights'),
                Tab(text: 'Recorrências'),
                Tab(text: 'Capturar'),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * .62,
              child: TabBarView(
                children: [
                  _insightsTab(report),
                  _recurringTab(report),
                  _captureTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightsTab(IntelligenceReport report) => ListView(
        children: [
          if (report.insights.isEmpty)
            const SurfaceCard(
              child: Text('Nenhum alerta relevante foi encontrado agora.'),
            )
          else
            ...report.insights.map(_insightCard),
          if (report.anomalies.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Movimentações fora do padrão',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...report.anomalies.map(
              (item) => SurfaceCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.manage_search_rounded),
                  title: Text(item.title),
                  subtitle: Text(item.message),
                  trailing: Text('R\$ ${_money(item.amount)}'),
                ),
              ),
            ),
          ],
        ],
      );

  Widget _insightCard(IntelligenceInsight item) {
    final color = switch (item.severity) {
      IntelligenceSeverity.info => FinoraColors.balance,
      IntelligenceSeverity.warning => FinoraColors.warning,
      IntelligenceSeverity.critical => FinoraColors.expense,
    };
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(item.message),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recurringTab(IntelligenceReport report) {
    if (report.subscriptions.isEmpty) {
      return const SurfaceCard(
        child: Text(
          'Ainda não encontrei pelo menos três meses de cobranças estáveis que pareçam recorrentes.',
        ),
      );
    }
    return ListView(
      children: report.subscriptions
          .map(
            (item) => SurfaceCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.repeat_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text('R\$ ${_money(item.averageAmount)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.occurrences} ocorrências · ${(item.confidence * 100).round()}% de confiança · próxima estimada em ${_date(item.nextExpectedDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _createRecurring(item),
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text('Transformar em recorrência'),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _captureTab() => ListView(
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Registrar por voz',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fale naturalmente, revise o texto e deixe o Finora preparar o lançamento antes de confirmar.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _voiceController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Ex.: gastei 45 reais de gasolina no Nubank',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : _toggleVoice,
                        icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded),
                        label: Text(_listening ? 'Parar' : 'Falar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _processing
                            ? null
                            : () => _interpret(_voiceController.text),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Preparar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ler comprovante ou print',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Selecione JPG, PNG ou WebP. A imagem é enviada ao Gemini somente para esta leitura e não fica salva no Finora.',
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _processing ? null : _pickReceipt,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(_processing ? 'Analisando...' : 'Selecionar imagem'),
                ),
                if (_receipt != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${_receipt!.merchant} · R\$ ${_money(_receipt!.amount)} · ${(_receipt!.confidence * 100).round()}% de confiança',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (_clarification != null) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_clarification!,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _choices
                        .map(
                          (choice) => ActionChip(
                            label: Text(choice),
                            onPressed: () => _answerClarification(choice),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          if (_suggestion != null) ...[
            const SizedBox(height: 10),
            _suggestionCard(_suggestion!),
          ],
        ],
      );

  Widget _suggestionCard(AiTransactionSuggestion item) => SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Confira antes de registrar',
                style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(item.title),
            Text('R\$ ${_money(item.amount)} · ${item.category}'),
            Text(
              item.paymentKind == PaymentKind.card
                  ? 'Cartão · ${context.read<FinanceStore>().findCard(item.cardId)?.name ?? item.accountName}'
                  : 'Conta · ${item.accountName}',
            ),
            Text('Data · ${_date(item.date)}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _suggestion = null),
                    child: const Text('Descartar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _confirmSuggestion,
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  static String _money(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}