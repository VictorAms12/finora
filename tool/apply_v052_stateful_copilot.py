from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf-8')


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding='utf-8')


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    if old not in text:
        raise RuntimeError(f'Marcador não encontrado em {path}: {old[:120]!r}')
    write(path, text.replace(old, new, 1))


def regex_replace_once(path: str, pattern: str, replacement: str) -> None:
    text = read(path)
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f'Regex não encontrou exatamente 1 ocorrência em {path}: {pattern}')
    write(path, updated)


# ---------------------------------------------------------------------------
# FinanceData: conversa do Copilot passa a fazer parte do estado persistente.
# ---------------------------------------------------------------------------
models = read('lib/models.dart')
if 'class CopilotChatMessageItem {' not in models:
    chat_model = r'''
class CopilotChatMessageItem {
  final String id;
  bool user;
  String text;
  List<String> followUps;
  String action;
  String? actionLabel;
  DateTime createdAt;

  CopilotChatMessageItem({
    required this.id,
    required this.user,
    required this.text,
    required this.createdAt,
    this.followUps = const [],
    this.action = 'none',
    this.actionLabel,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user,
        'text': text,
        'followUps': followUps,
        'action': action,
        'actionLabel': actionLabel,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CopilotChatMessageItem.fromJson(Map<String, dynamic> j) =>
      CopilotChatMessageItem(
        id: j['id'] as String? ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        user: j['user'] as bool? ?? false,
        text: j['text'] as String? ?? '',
        followUps: ((j['followUps'] as List?) ?? const [])
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .take(4)
            .toList(growable: false),
        action: j['action'] as String? ?? 'none',
        actionLabel: j['actionLabel'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

'''
    models = models.replace('class TransactionItem {', chat_model + 'class TransactionItem {', 1)

models = models.replace(
    "  final List<CopilotMemoryItem> copilotMemories;\n  DateTime? trackingMonth;",
    "  final List<CopilotMemoryItem> copilotMemories;\n"
    "  final List<CopilotChatMessageItem> copilotChat;\n"
    "  String copilotDraft;\n"
    "  String copilotMode;\n"
    "  String? copilotPendingTransaction;\n"
    "  DateTime? copilotChatUpdatedAt;\n"
    "  DateTime? trackingMonth;",
    1,
)
models = models.replace(
    "    required this.copilotMemories,\n    required this.trackingMonth,",
    "    required this.copilotMemories,\n"
    "    this.copilotChat = const [],\n"
    "    this.copilotDraft = '',\n"
    "    this.copilotMode = 'chat',\n"
    "    this.copilotPendingTransaction,\n"
    "    this.copilotChatUpdatedAt,\n"
    "    required this.trackingMonth,",
    1,
)
models = models.replace(
    "    'copilotMemories': copilotMemories.map((e) => e.toJson()).toList(),\n    'trackingMonth':",
    "    'copilotMemories': copilotMemories.map((e) => e.toJson()).toList(),\n"
    "    'copilotChat': copilotChat.map((e) => e.toJson()).toList(),\n"
    "    'copilotDraft': copilotDraft,\n"
    "    'copilotMode': copilotMode,\n"
    "    'copilotPendingTransaction': copilotPendingTransaction,\n"
    "    'copilotChatUpdatedAt': copilotChatUpdatedAt?.toIso8601String(),\n"
    "    'trackingMonth':",
    1,
)
from_json_marker = """    copilotMemories: ((j['copilotMemories'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => CopilotMemoryItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.value.trim().isNotEmpty)
        .take(40)
        .toList(),
    trackingMonth:"""
from_json_replacement = """    copilotMemories: ((j['copilotMemories'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => CopilotMemoryItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.value.trim().isNotEmpty)
        .take(40)
        .toList(),
    copilotChat: ((j['copilotChat'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => CopilotChatMessageItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.text.trim().isNotEmpty)
        .toList()
        .reversed
        .take(120)
        .toList()
        .reversed
        .toList(),
    copilotDraft: (j['copilotDraft'] as String? ?? '')
        .substring(0, (j['copilotDraft'] as String? ?? '').length.clamp(0, 2000)),
    copilotMode: j['copilotMode'] == 'transaction' ? 'transaction' : 'chat',
    copilotPendingTransaction: j['copilotPendingTransaction'] as String?,
    copilotChatUpdatedAt:
        DateTime.tryParse(j['copilotChatUpdatedAt'] as String? ?? ''),
    trackingMonth:"""
if from_json_marker not in models:
    raise RuntimeError('FinanceData.fromJson marker não encontrado')
models = models.replace(from_json_marker, from_json_replacement, 1)
write('lib/models.dart', models)

# ---------------------------------------------------------------------------
# Store modular: sessão, diagnóstico e insights determinísticos.
# ---------------------------------------------------------------------------
replace_once(
    'lib/store.dart',
    "part 'store_backup.dart';",
    "part 'store_backup.dart';\npart 'store_copilot.dart';\npart 'store_diagnostics.dart';\npart 'store_insights.dart';",
)

write(
    'lib/store_copilot.dart',
    r'''part of 'store.dart';

extension FinanceStoreCopilotSession on FinanceStore {
  void saveCopilotSession({
    required List<CopilotChatMessageItem> messages,
    required String draft,
    required String mode,
    String? pendingTransaction,
  }) {
    final normalizedMessages = messages
        .where((message) => message.text.trim().isNotEmpty)
        .map(
          (message) => CopilotChatMessageItem(
            id: message.id,
            user: message.user,
            text: message.text.trim(),
            followUps: message.followUps
                .where((value) => value.trim().isNotEmpty)
                .take(4)
                .toList(growable: false),
            action: message.action,
            actionLabel: message.actionLabel,
            createdAt: message.createdAt,
          ),
        )
        .toList(growable: true);
    if (normalizedMessages.length > 120) {
      normalizedMessages.removeRange(0, normalizedMessages.length - 120);
    }

    final normalizedDraft = draft.length > 2000 ? draft.substring(0, 2000) : draft;
    final normalizedMode = mode == 'transaction' ? 'transaction' : 'chat';
    final normalizedPending = pendingTransaction?.trim();
    final cleanPending = normalizedPending == null || normalizedPending.isEmpty
        ? null
        : (normalizedPending.length > 4000
            ? normalizedPending.substring(0, 4000)
            : normalizedPending);

    var changed = data.copilotChat.length != normalizedMessages.length ||
        data.copilotDraft != normalizedDraft ||
        data.copilotMode != normalizedMode ||
        data.copilotPendingTransaction != cleanPending;

    if (!changed) {
      for (var i = 0; i < normalizedMessages.length; i++) {
        final before = data.copilotChat[i];
        final after = normalizedMessages[i];
        if (before.id != after.id ||
            before.user != after.user ||
            before.text != after.text ||
            before.action != after.action ||
            before.actionLabel != after.actionLabel ||
            before.followUps.join('\u0000') != after.followUps.join('\u0000')) {
          changed = true;
          break;
        }
      }
    }
    if (!changed) return;

    data.copilotChat
      ..clear()
      ..addAll(normalizedMessages);
    data.copilotDraft = normalizedDraft;
    data.copilotMode = normalizedMode;
    data.copilotPendingTransaction = cleanPending;
    data.copilotChatUpdatedAt = DateTime.now();
    commit();
  }

  void clearCopilotSession() {
    if (data.copilotChat.isEmpty &&
        data.copilotDraft.isEmpty &&
        data.copilotPendingTransaction == null &&
        data.copilotMode == 'chat') {
      return;
    }
    data.copilotChat.clear();
    data.copilotDraft = '';
    data.copilotMode = 'chat';
    data.copilotPendingTransaction = null;
    data.copilotChatUpdatedAt = DateTime.now();
    commit();
  }
}
''',
)

write(
    'lib/store_diagnostics.dart',
    r'''part of 'store.dart';

extension FinanceStoreDiagnostics on FinanceStore {
  List<String> get dataHealthIssues {
    final issues = <String>[];

    void duplicateIds(String label, Iterable<String> ids) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) {
          issues.add('$label possui identificador duplicado.');
          return;
        }
      }
    }

    duplicateIds('Contas', data.accounts.map((e) => e.id));
    duplicateIds('Cartões', data.cards.map((e) => e.id));
    duplicateIds('Movimentações', data.transactions.map((e) => e.id));
    duplicateIds('Planejamentos', data.planned.map((e) => e.id));
    duplicateIds('Metas', data.goals.map((e) => e.id));
    duplicateIds('Reservas', data.reserves.map((e) => e.id));
    duplicateIds('Recorrências', data.recurringRules.map((e) => e.id));
    duplicateIds('Parcelamentos', data.installmentPlans.map((e) => e.id));

    for (final account in data.accounts) {
      if (!account.balance.isFinite) {
        issues.add('A conta ${account.name} possui saldo inválido.');
      }
    }
    for (final card in data.cards) {
      if (!card.limit.isFinite || !card.used.isFinite || card.limit < 0 || card.used < 0) {
        issues.add('O cartão ${card.name} possui limite ou fatura inválidos.');
      }
    }
    for (final tx in data.transactions) {
      if (!tx.amount.isFinite || tx.amount <= 0) {
        issues.add('A movimentação ${tx.title} possui valor inválido.');
        continue;
      }
      if (tx.type == TransactionType.transfer) {
        final pair = transferAccounts(tx);
        if (pair == null ||
            findAccount(pair[0]) == null ||
            findAccount(pair[1]) == null) {
          issues.add('A transferência ${tx.title} referencia uma conta inexistente.');
        }
      } else if (tx.paymentKind == PaymentKind.card &&
          tx.type == TransactionType.expense) {
        if (findCard(tx.cardId) == null) {
          issues.add('A compra ${tx.title} referencia um cartão inexistente.');
        }
      } else if (findAccount(tx.account) == null) {
        issues.add('A movimentação ${tx.title} referencia uma conta inexistente.');
      }
    }

    for (final planned in data.planned.where((e) => e.status == PlannedStatus.planned)) {
      if (!planned.amount.isFinite || planned.amount <= 0) {
        issues.add('O previsto ${planned.title} possui valor inválido.');
      }
      if (planned.paymentKind == PaymentKind.card &&
          planned.type == TransactionType.expense) {
        if (findCard(planned.cardId) == null) {
          issues.add('O previsto ${planned.title} referencia um cartão inexistente.');
        }
      } else if (planned.sourceName.isNotEmpty && findAccount(planned.sourceName) == null) {
        issues.add('O previsto ${planned.title} referencia uma conta inexistente.');
      }
    }

    final snapshotMonths = <String>{};
    for (final snapshot in data.snapshots) {
      final key = '${snapshot.month.year}-${snapshot.month.month}';
      if (!snapshotMonths.add(key)) {
        issues.add('Há mais de um fechamento salvo para ${snapshot.month.month}/${snapshot.month.year}.');
      }
      if (!snapshot.openingBalance.isFinite ||
          !snapshot.closingBalance.isFinite ||
          !snapshot.income.isFinite ||
          !snapshot.expense.isFinite) {
        issues.add('Um fechamento mensal possui valores inválidos.');
      }
    }

    if (data.copilotChat.length > 120) {
      issues.add('O histórico do Copilot ultrapassou o limite local esperado.');
    }

    return issues.take(30).toList(growable: false);
  }
}
''',
)

write(
    'lib/store_insights.dart',
    r'''part of 'store.dart';

enum FinoraInsightSeverity { info, attention, warning }

class FinoraInsight {
  final String title;
  final String message;
  final String question;
  final FinoraInsightSeverity severity;

  const FinoraInsight({
    required this.title,
    required this.message,
    required this.question,
    this.severity = FinoraInsightSeverity.info,
  });
}

extension FinanceStoreInsights on FinanceStore {
  List<FinoraInsight> get smartInsights {
    final insights = <FinoraInsight>[];
    final now = DateTime.now();
    final month = selectedMonth;

    if (selectedIsCurrent && overduePlannedCount > 0) {
      insights.add(
        FinoraInsight(
          title: 'Compromissos atrasados',
          message: '$overduePlannedCount item(ns) previsto(s) já passaram da data.',
          question: 'Quais compromissos estão atrasados?',
          severity: FinoraInsightSeverity.warning,
        ),
      );
    }

    if (selectedIsCurrent) {
      final today = DateTime(now.year, now.month, now.day);
      final limit = today.add(const Duration(days: 7));
      final nextSevenDays = data.planned
          .where(
            (item) =>
                item.status == PlannedStatus.planned &&
                item.type == TransactionType.expense &&
                !item.date.isBefore(today) &&
                !item.date.isAfter(limit),
          )
          .fold<double>(0, (sum, item) => sum + item.amount);
      if (nextSevenDays > 0) {
        insights.add(
          FinoraInsight(
            title: 'Próximos 7 dias',
            message: 'Há R\$ ${nextSevenDays.toStringAsFixed(2).replaceAll('.', ',')} previstos para sair.',
            question: 'O que vence nos próximos 7 dias?',
            severity: nextSevenDays > cashBalance
                ? FinoraInsightSeverity.warning
                : FinoraInsightSeverity.attention,
          ),
        );
      }
    }

    final previous = expenseForMonth(DateTime(month.year, month.month - 1));
    final current = expenseForMonth(month);
    if (previous > 0 && current > previous * 1.20) {
      final percent = ((current - previous) / previous * 100).round();
      insights.add(
        FinoraInsight(
          title: 'Despesas aceleraram',
          message: 'Você está $percent% acima do mês anterior em despesas.',
          question: 'Por que meus gastos aumentaram?',
          severity: FinoraInsightSeverity.attention,
        ),
      );
    }

    final categoryMap = <String, double>{};
    for (final tx in transactionsForMonth(month)) {
      if (tx.type != TransactionType.expense) continue;
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
    }
    if (current > 0 && categoryMap.isNotEmpty) {
      final top = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final share = top.first.value / current;
      if (share >= .40) {
        insights.add(
          FinoraInsight(
            title: '${top.first.key} concentra seus gastos',
            message: '${(share * 100).round()}% das despesas do período estão nessa categoria.',
            question: 'Analise meus gastos em ${top.first.key}.',
          ),
        );
      }
    }

    if (selectedIsCurrent && now.day > 0) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (final budget in data.budgets) {
        final used = categoryMap[budget.category] ?? 0;
        if (budget.limit <= 0 || used <= 0) continue;
        final projected = used / now.day * daysInMonth;
        if (used <= budget.limit && projected > budget.limit * 1.05) {
          insights.add(
            FinoraInsight(
              title: 'Orçamento de ${budget.category} em risco',
              message: 'No ritmo atual, a categoria tende a ultrapassar o limite antes do fim do mês.',
              question: 'Como está meu orçamento de ${budget.category}?',
              severity: FinoraInsightSeverity.attention,
            ),
          );
        }
      }
    }

    for (final card in data.cards) {
      if (card.limit <= 0) continue;
      final ratio = card.used / card.limit;
      if (ratio >= .80) {
        insights.add(
          FinoraInsight(
            title: 'Limite do ${card.name}',
            message: '${(ratio * 100).round()}% do limite está comprometido.',
            question: 'Como está o ${card.name}?',
            severity: ratio >= .95
                ? FinoraInsightSeverity.warning
                : FinoraInsightSeverity.attention,
          ),
        );
      }
    }

    insights.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return insights.take(6).toList(growable: false);
  }
}
''',
)

# ---------------------------------------------------------------------------
# HomeShell: IndexedStack mantém páginas vivas e elimina recriação por aba.
# ---------------------------------------------------------------------------
home_replacement = r'''class _HomeShellState extends State<HomeShell> {
  int index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardScreen(key: PageStorageKey('dashboard')),
      const PlanningScreen(key: PageStorageKey('planning')),
      FinoraAiScreen(
        key: const PageStorageKey('finora-ai'),
        onNavigatePage: go,
      ),
      const TransactionsScreen(key: PageStorageKey('transactions')),
      const MoreScreen(key: PageStorageKey('more')),
    ];
  }

  void go(int page) {
    if (page == index || page < 0 || page >= _pages.length) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => index = page);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 880;
          final pageArea = Expanded(
            child: KeyedSubtree(
              key: const ValueKey('finora-page-area'),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: IndexedStack(index: index, children: _pages),
                ),
              ),
            ),
          );

          final content = CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
                  desktop
                      ? showDesktopQuickActions(context)
                      : showQuickActions(context),
              const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => go(0),
              const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => go(1),
              const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => go(2),
              const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => go(3),
              const SingleActivator(LogicalKeyboardKey.digit5, control: true): () => go(4),
            },
            child: Focus(
              autofocus: true,
              child: Row(
                children: [
                  if (desktop) ...[
                    _DesktopSidebar(
                      index: index,
                      onNavigate: go,
                      onNew: () => showDesktopQuickActions(context),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                  ],
                  pageArea,
                ],
              ),
            ),
          );

          return Scaffold(
            body: SafeArea(child: content),
            floatingActionButton: desktop || index == 2
                ? null
                : FloatingActionButton.small(
                    heroTag: 'finora-main-add',
                    tooltip: 'Novo lançamento',
                    onPressed: () => showQuickActions(context),
                    backgroundColor: FinoraColors.goldBright,
                    foregroundColor: Colors.black,
                    elevation: 3,
                    child: const Icon(Icons.add_rounded),
                  ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: desktop
                ? null
                : BottomAppBar(
                    height: 72,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF050505)
                        : Colors.white,
                    surfaceTintColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    child: Row(
                      children: [
                        _mobileNav(context, Icons.home_rounded, 'Início', 0),
                        _mobileNav(context, Icons.calendar_month_rounded, 'Planejar', 1),
                        _mobileNav(
                          context,
                          Icons.auto_awesome_rounded,
                          'IA',
                          2,
                          accent: FinoraColors.investment,
                        ),
                        _mobileNav(context, Icons.swap_vert_rounded, 'Movimentos', 3),
                        _mobileNav(context, Icons.grid_view_rounded, 'Mais', 4),
                      ],
                    ),
                  ),
          );
        },
      );

  Widget _mobileNav'''
regex_replace_once(
    'lib/ui/home_shell.dart',
    r'class _HomeShellState extends State<HomeShell> \{.*?\n  Widget _mobileNav',
    home_replacement,
)

# ---------------------------------------------------------------------------
# Chat stateful: hidrata/persiste conversa, rascunho e clarificação pendente.
# ---------------------------------------------------------------------------
ai = read('lib/ui/ai_assistant.dart')
if not ai.startswith("import 'dart:async';"):
    ai = "import 'dart:async';\n\n" + ai

chat_class = r'''class _ChatMessage {
  final String id;
  final DateTime createdAt;
  final bool user;
  final String text;
  final AiTransactionSuggestion? suggestion;
  final CopilotActionProposal? proposal;
  final List<String> followUps;
  final AiAssistantAction action;
  final String? actionLabel;
  bool handled = false;

  _ChatMessage({
    String? id,
    DateTime? createdAt,
    required this.user,
    required this.text,
    this.suggestion,
    this.proposal,
    this.followUps = const [],
    this.action = AiAssistantAction.none,
    this.actionLabel,
  })  : id = id ?? FinanceStore.newId(),
        createdAt = createdAt ?? DateTime.now();

  factory _ChatMessage.fromStored(CopilotChatMessageItem item) => _ChatMessage(
        id: item.id,
        createdAt: item.createdAt,
        user: item.user,
        text: item.text,
        followUps: item.followUps,
        action: AiAssistantAction.values.firstWhere(
          (value) => value.name == item.action,
          orElse: () => AiAssistantAction.none,
        ),
        actionLabel: item.actionLabel,
      );
}
'''
ai, count = re.subn(
    r'class _ChatMessage \{.*?\n\}\n\nclass FinoraAiScreen',
    chat_class + '\nclass FinoraAiScreen',
    ai,
    count=1,
    flags=re.S,
)
if count != 1:
    raise RuntimeError('Não foi possível substituir _ChatMessage')

state_header = r'''class _FinoraAiScreenState extends State<FinoraAiScreen>
    with AutomaticKeepAliveClientMixin<FinoraAiScreen>, WidgetsBindingObserver {
  final _gemini = const GeminiService();
  final _ai = const FinoraAiService();
  final _composer = TextEditingController();
  final _keyController = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _messages = <_ChatMessage>[];

  FinanceStore? _store;
  Timer? _draftTimer;
  bool _hydrated = false;
  bool _checkingKey = true;
  bool _hasKey = false;
  bool _busy = false;
  bool _busyKey = false;
  bool _obscureKey = true;
  bool _showKeyForm = false;
  _AiMode _mode = _AiMode.chat;
  String _busyLabel = 'Analisando...';
  String? _pendingTransaction;
'''
ai, count = re.subn(
    r'class _FinoraAiScreenState extends State<FinoraAiScreen> \{.*?  String\? _pendingTransaction;\n',
    state_header,
    ai,
    count=1,
    flags=re.S,
)
if count != 1:
    raise RuntimeError('Não foi possível substituir cabeçalho do state da IA')

lifecycle_old = r'''  @override
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
'''
lifecycle_new = r'''  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshKey();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _store = context.read<FinanceStore>();
    final data = _store!.data;
    if (data.copilotChat.isEmpty) {
      _messages.add(_welcomeMessage());
    } else {
      _messages.addAll(data.copilotChat.map(_ChatMessage.fromStored));
    }
    _composer.text = data.copilotDraft;
    _mode = data.copilotMode == 'transaction' ? _AiMode.transaction : _AiMode.chat;
    _pendingTransaction = data.copilotPendingTransaction;
    _composer.addListener(_onComposerChanged);
    _hydrated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _persistState();
      _scrollToEnd();
    });
  }

  _ChatMessage _welcomeMessage() => _ChatMessage(
        user: false,
        text:
            'Oi! Posso te ajudar a entender seus gastos, conferir saldos, planejar o mês ou registrar uma movimentação. Pode falar do seu jeito.',
        followUps: const [
          'Como está meu mês?',
          'Quanto posso gastar?',
          'Quais são as próximas contas?',
        ],
      );

  void _onComposerChanged() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 650), _persistState);
  }

  void _persistState() {
    if (!_hydrated || _store == null) return;
    final persistent = _messages
        .where((message) => message.suggestion == null && message.proposal == null)
        .map(
          (message) => CopilotChatMessageItem(
            id: message.id,
            user: message.user,
            text: message.text,
            followUps: message.followUps,
            action: message.action.name,
            actionLabel: message.actionLabel,
            createdAt: message.createdAt,
          ),
        )
        .toList(growable: false);
    _store!.saveCopilotSession(
      messages: persistent,
      draft: _composer.text,
      mode: _mode.name,
      pendingTransaction: _pendingTransaction,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _persistState();
    }
  }

  @override
  void didChangeMetrics() {
    _scrollToEnd();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    _composer.removeListener(_onComposerChanged);
    _composer.dispose();
    _keyController.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }
'''
if lifecycle_old not in ai:
    raise RuntimeError('Lifecycle antigo da IA não encontrado')
ai = ai.replace(lifecycle_old, lifecycle_new, 1)

# Local answers now receive the persisted conversation context.
ai = ai.replace(
    "            ? null\n            : _ai.tryLocalAnswer(store, clean);",
    "            ? null\n            : _ai.tryLocalAnswer(\n                store,\n                clean,\n                conversationContext: history,\n              );",
    1,
)

# Every scroll-worthy state transition also syncs the local session first.
ai = ai.replace(
    "  void _scrollToEnd() {\n    WidgetsBinding.instance.addPostFrameCallback",
    "  void _scrollToEnd() {\n    _persistState();\n    WidgetsBinding.instance.addPostFrameCallback",
    1,
)

# New conversation clears the persisted session atomically.
clear_old = r'''  void _clear() {
    setState(() {
      _messages
        ..clear()
        ..add(
          _ChatMessage(
            user: false,
            text: 'Tudo limpo. O que você quer ver agora?',
            followUps: const ['Como está meu mês?', 'Quanto posso gastar?'],
          ),
        );
      _mode = _AiMode.chat;
      _pendingTransaction = null;
    });
  }
'''
clear_new = r'''  void _clear() {
    _store?.clearCopilotSession();
    setState(() {
      _messages
        ..clear()
        ..add(
          _ChatMessage(
            user: false,
            text: 'Nova conversa. O que você quer ver agora?',
            followUps: const ['Como está meu mês?', 'Quanto posso gastar?'],
          ),
        );
      _composer.clear();
      _mode = _AiMode.chat;
      _pendingTransaction = null;
    });
    _scrollToEnd();
  }
'''
if clear_old not in ai:
    raise RuntimeError('Método _clear antigo não encontrado')
ai = ai.replace(clear_old, clear_new, 1)

# Start transaction/mode changes persist even before sending.
ai = ai.replace(
    "    _focus.requestFocus();\n  }\n\n  void _handleAction",
    "    _persistState();\n    _focus.requestFocus();\n  }\n\n  void _handleAction",
    1,
)

mode_old = r'''                onTap: () => setState(() {
                  _mode = _AiMode.chat;
                  _pendingTransaction = null;
                }),'''
mode_new = r'''                onTap: () {
                  setState(() {
                    _mode = _AiMode.chat;
                    _pendingTransaction = null;
                  });
                  _persistState();
                },'''
if mode_old not in ai:
    raise RuntimeError('Mode pill chat não encontrado')
ai = ai.replace(mode_old, mode_new, 1)

# KeepAlive build + compact landscape/keyboard behavior.
ai = ai.replace(
    "  Widget build(BuildContext context) {\n    final setup =",
    "  Widget build(BuildContext context) {\n    super.build(context);\n    final setup =",
    1,
)
ai = ai.replace(
    "    final count = _messages.length + (setup ? 1 : 0) + (_busy ? 1 : 0);\n\n    return Column(\n      children: [\n        _header(context),\n        _quickActions(),",
    "    final count = _messages.length + (setup ? 1 : 0) + (_busy ? 1 : 0);\n"
    "    final media = MediaQuery.of(context);\n"
    "    final compactHeight = media.size.height < 430 || media.viewInsets.bottom > 0;\n\n"
    "    return Column(\n      children: [\n        _header(context),\n        if (!compactHeight) _quickActions(),",
    1,
)

# Add deterministic insights as a quick action.
ai = ai.replace(
    "          _chip(\n            Icons.add_card_rounded,\n            'Registrar',",
    "          _chip(\n            Icons.lightbulb_outline_rounded,\n            'Insights',\n            enabled ? () => _askPreset('O que merece minha atenção agora?') : null,\n          ),\n          _chip(\n            Icons.add_card_rounded,\n            'Registrar',",
    1,
)
write('lib/ui/ai_assistant.dart', ai)

# ---------------------------------------------------------------------------
# Finora AI: respostas locais também usam continuidade e insights do núcleo.
# ---------------------------------------------------------------------------
finance_ai = read('lib/ai/finance_ai.dart')
finance_ai = finance_ai.replace(
    "    final local = tryLocalAnswer(store, clean);",
    "    final local = tryLocalAnswer(\n      store,\n      clean,\n      conversationContext: conversationContext,\n    );",
    1,
)
finance_ai = finance_ai.replace(
    "  AiAssistantReply? tryLocalAnswer(FinanceStore store, String question) {\n    final query = const FinancialQueryEngine().answer(store, question);",
    "  AiAssistantReply? tryLocalAnswer(\n    FinanceStore store,\n    String question, {\n    String conversationContext = '',\n  }) {\n    final contextual = _contextualLocalQuestion(question, conversationContext);\n    final clean = _fold(contextual);\n\n    if (_hasAny(clean, ['insight', 'merece minha atencao', 'merece atenção', 'o que devo observar'])) {\n      final insights = store.smartInsights;\n      if (insights.isEmpty) {\n        return const AiAssistantReply(\n          message: 'Não encontrei nenhum alerta relevante agora. Seus dados atuais não mostram um desvio que mereça destaque.',\n          local: true,\n        );\n      }\n      final message = insights\n          .take(3)\n          .map((item) => '${item.title}: ${item.message}')\n          .join('\\n');\n      return AiAssistantReply(\n        message: message,\n        followUps: insights.take(3).map((item) => item.question).toList(growable: false),\n        local: true,\n      );\n    }\n\n    final query = const FinancialQueryEngine().answer(store, contextual);",
    1,
)
# Remove the duplicate `clean` declaration that follows the query block.
finance_ai = finance_ai.replace("\n    final clean = _fold(question);\n\n    if (_hasAny(clean,", "\n    if (_hasAny(clean,", 1)
helper_marker = "  AiAssistantIntent detectIntent(String question) {"
helper = r'''  String _contextualLocalQuestion(String question, String conversationContext) {
    final clean = _fold(question);
    if (conversationContext.trim().isEmpty || clean.length > 45) return question;
    final continuation = _hasAny(clean, [
      'e mes passado',
      'e mês passado',
      'e antes',
      'e esse',
      'e essa',
      'e o outro',
      'e a outra',
      'por que',
      'por quê',
    ]);
    if (!continuation) return question;
    final lines = conversationContext.split('\n').reversed;
    for (final line in lines) {
      if (!line.startsWith('Usuário:')) continue;
      final previous = line.substring('Usuário:'.length).trim();
      if (previous.isNotEmpty && previous != question.trim()) {
        return '$previous. Continuação: ${question.trim()}';
      }
    }
    return question;
  }

'''
if helper_marker not in finance_ai:
    raise RuntimeError('detectIntent marker não encontrado')
finance_ai = finance_ai.replace(helper_marker, helper + helper_marker, 1)
write('lib/ai/finance_ai.dart', finance_ai)

# ---------------------------------------------------------------------------
# Virada de mês mais explícita + insights determinísticos no dashboard.
# ---------------------------------------------------------------------------
dashboard = read('lib/ui/dashboard.dart')
month_marker = "          const MonthSwitcher(),\n          const SizedBox(height: 10),"
month_banner = r'''          const MonthSwitcher(),
          if (store.selectedIsCurrent &&
              DateTime.now().day <= 3 &&
              (store.previousMonthExpense > 0 ||
                  store.incomeForMonth(store.previousSelectedMonth) > 0)) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              borderColor: FinoraColors.balance.withValues(alpha: .24),
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: FinoraColors.balance),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${monthLong[store.selectedMonth.month - 1]} começou',
                          style: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${monthLong[store.previousSelectedMonth.month - 1]} terminou com ${money(context, store.previousMonthExpense)} em gastos.',
                          style: TextStyle(
                            fontSize: 8.8,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: store.previousMonth,
                    child: Text('Ver ${monthShort[store.previousSelectedMonth.month - 1]}'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),'''
if month_marker not in dashboard:
    raise RuntimeError('MonthSwitcher dashboard marker não encontrado')
dashboard = dashboard.replace(month_marker, month_banner, 1)

dashboard = dashboard.replace(
    "                            'Entradas',\n                            store.monthIncome,",
    "                            'Entradas · ${monthShort[store.selectedMonth.month - 1]}',\n                            store.monthIncome,",
    1,
)
dashboard = dashboard.replace(
    "                            'Saídas',\n                            store.monthExpense,",
    "                            'Saídas · ${monthShort[store.selectedMonth.month - 1]}',\n                            store.monthExpense,",
    1,
)
insight_marker = "          const SizedBox(height: 14),\n          sectionTitle(context, 'ESTE PERÍODO', 'Visão rápida'),"
insight_block = r'''          if (!store.selectedIsFuture && store.smartInsights.isNotEmpty) ...[
            const SizedBox(height: 14),
            sectionTitle(context, 'INSIGHTS', 'O que merece atenção'),
            const SizedBox(height: 7),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: store.smartInsights.take(3).map((insight) {
                  final color = switch (insight.severity) {
                    FinoraInsightSeverity.warning => FinoraColors.expense,
                    FinoraInsightSeverity.attention => FinoraColors.warning,
                    FinoraInsightSeverity.info => FinoraColors.balance,
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_graph_rounded, size: 18, color: color),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                insight.title,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                insight.message,
                                style: TextStyle(
                                  fontSize: 8.7,
                                  height: 1.35,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          sectionTitle(context, 'ESTE PERÍODO', 'Visão rápida'),'''
if insight_marker not in dashboard:
    raise RuntimeError('Insight dashboard marker não encontrado')
dashboard = dashboard.replace(insight_marker, insight_block, 1)
write('lib/ui/dashboard.dart', dashboard)

# ---------------------------------------------------------------------------
# Histórico global pesquisável, sem abandonar o filtro mensal existente.
# ---------------------------------------------------------------------------
transactions = read('lib/ui/transactions.dart')
transactions = transactions.replace(
    "  String _search = '';\n  int _visibleCount = _pageSize;",
    "  String _search = '';\n  bool _allMonths = false;\n  int _visibleCount = _pageSize;",
    1,
)
transactions = transactions.replace(
    "    Iterable<TransactionItem> filtered = store.monthTransactions;",
    "    Iterable<TransactionItem> filtered = _allMonths\n"
    "        ? (store.data.transactions.toList()\n"
    "          ..sort((a, b) => b.date.compareTo(a.date)))\n"
    "        : store.monthTransactions;",
    1,
)
transactions = transactions.replace(
    "          '${item.title} ${item.category} ${item.account}'\n              .toLowerCase()",
    "          '${item.title} ${item.category} ${item.account} ${item.note} ${item.amount.toStringAsFixed(2)}'\n              .toLowerCase()",
    1,
)
transactions = transactions.replace(
    "          const MonthSwitcher(),\n          const SizedBox(height: 10),",
    "          Row(\n            children: [\n              Expanded(\n                child: _allMonths\n                    ? const Text(\n                        'Histórico completo',\n                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),\n                      )\n                    : const MonthSwitcher(),\n              ),\n              const SizedBox(width: 8),\n              FilterChip(\n                label: const Text('Todos os meses'),\n                selected: _allMonths,\n                onSelected: (value) => setState(() {\n                  _allMonths = value;\n                  _visibleCount = _pageSize;\n                }),\n              ),\n            ],\n          ),\n          const SizedBox(height: 10),",
    1,
)
transactions = transactions.replace(
    "                    subtitle: 'Os lançamentos deste mês aparecerão aqui.',",
    "                    subtitle: _allMonths\n                        ? 'Nenhuma movimentação corresponde aos filtros.'\n                        : 'Os lançamentos deste mês aparecerão aqui.',",
    1,
)
write('lib/ui/transactions.dart', transactions)

# ---------------------------------------------------------------------------
# Orçamento mostra restante, percentual e projeção de ritmo.
# ---------------------------------------------------------------------------
tiles = read('lib/ui/tiles.dart')
old_budget_start = r'''  @override
  Widget build(BuildContext context) {
    final used = context.select<FinanceStore, double>(
      (store) => store.expensesByCategory[item.category] ?? 0,
    );
    final ratio = item.limit <= 0 ? 0.0 : used / item.limit;
    final over = ratio > 1;
    return Padding('''
new_budget_start = r'''  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final used = store.expensesByCategory[item.category] ?? 0;
    final ratio = item.limit <= 0 ? 0.0 : used / item.limit;
    final over = ratio > 1;
    final remaining = (item.limit - used).clamp(0.0, double.infinity).toDouble();
    final now = DateTime.now();
    double? projected;
    if (store.selectedIsCurrent && now.day > 0 && used > 0) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      projected = used / now.day * daysInMonth;
    }
    final projectedOver = projected != null && projected > item.limit && !over;
    return Padding('''
if old_budget_start not in tiles:
    raise RuntimeError('BudgetProgress start marker não encontrado')
tiles = tiles.replace(old_budget_start, new_budget_start, 1)
tiles = tiles.replace(
    "          const SizedBox(height: 6),\n          LinearProgressIndicator(",
    "          const SizedBox(height: 4),\n"
    "          Align(\n"
    "            alignment: Alignment.centerLeft,\n"
    "            child: Text(\n"
    "              over\n"
    "                  ? '${(ratio * 100).round()}% usado · excedeu em ${money(context, used - item.limit)}'\n"
    "                  : '${(ratio * 100).round()}% usado · ${money(context, remaining)} restantes',\n"
    "              style: TextStyle(\n"
    "                fontSize: 8.2,\n"
    "                color: over ? FinoraColors.expense : Theme.of(context).colorScheme.onSurfaceVariant,\n"
    "              ),\n"
    "            ),\n"
    "          ),\n"
    "          if (projectedOver) ...[\n"
    "            const SizedBox(height: 3),\n"
    "            Align(\n"
    "              alignment: Alignment.centerLeft,\n"
    "              child: Text(\n"
    "                'Ritmo atual: cerca de ${money(context, projected!)} até o fim do mês',\n"
    "                style: const TextStyle(\n"
    "                  fontSize: 8.2,\n"
    "                  color: FinoraColors.warning,\n"
    "                  fontWeight: FontWeight.w700,\n"
    "                ),\n"
    "              ),\n"
    "            ),\n"
    "          ],\n"
    "          const SizedBox(height: 6),\n"
    "          LinearProgressIndicator(",
    1,
)
write('lib/ui/tiles.dart', tiles)

# ---------------------------------------------------------------------------
# Diagnóstico local acessível nas configurações.
# ---------------------------------------------------------------------------
write(
    'lib/ui/data_health.dart',
    r'''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sqlite_store.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

class DataHealthScreen extends StatefulWidget {
  const DataHealthScreen({super.key});

  @override
  State<DataHealthScreen> createState() => _DataHealthScreenState();
}

class _DataHealthScreenState extends State<DataHealthScreen> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final issues = store.dataHealthIssues;
    final encodedKb = store.data.encode().length / 1024;

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico dos dados')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SurfaceCard(
            borderColor: (issues.isEmpty ? FinoraColors.income : FinoraColors.warning)
                .withValues(alpha: .28),
            child: Row(
              children: [
                Icon(
                  issues.isEmpty ? Icons.verified_rounded : Icons.warning_amber_rounded,
                  color: issues.isEmpty ? FinoraColors.income : FinoraColors.warning,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issues.isEmpty ? 'Estrutura consistente' : '${issues.length} ponto(s) para revisar',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        store.sqliteActive
                            ? 'SQLite ativo e espelho de segurança disponível.'
                            : 'SQLite indisponível; o Finora está usando o fallback legado.',
                        style: const TextStyle(fontSize: 8.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              children: [
                _row('Movimentações', store.data.transactions.length.toString()),
                _row('Planejamentos', store.data.planned.length.toString()),
                _row('Contas / cartões', '${store.data.accounts.length} / ${store.data.cards.length}'),
                _row('Fechamentos mensais', store.data.snapshots.length.toString()),
                _row('Mensagens do Copilot', store.data.copilotChat.length.toString()),
                _row('Estado serializado', '${encodedKb.toStringAsFixed(1)} KB'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (store is SqliteFinanceStore)
            FutureBuilder<int>(
              key: ValueKey(_revision),
              future: store.indexedFinanceRowCount(),
              builder: (context, snapshot) => SurfaceCard(
                child: _row(
                  'Índice financeiro SQLite',
                  snapshot.hasData ? '${snapshot.data} linha(s)' : 'verificando...',
                ),
              ),
            ),
          if (store.sqliteFailure case final failure?) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              borderColor: FinoraColors.expense.withValues(alpha: .22),
              child: Text(
                failure,
                style: const TextStyle(fontSize: 8.5, height: 1.4),
              ),
            ),
          ],
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('VERIFICAÇÃO', style: eyebrowStyle(context)),
            const SizedBox(height: 7),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: issues
                    .map(
                      (issue) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: FinoraColors.warning),
                            const SizedBox(width: 8),
                            Expanded(child: Text(issue, style: const TextStyle(fontSize: 9.2))),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _revision++),
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Verificar novamente'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    await store.flushPersistence();
                    if (!context.mounted) return;
                    setState(() => _revision++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Persistência sincronizada.')),
                    );
                  },
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Sincronizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 9.5))),
            Text(value, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}
''',
)

settings = read('lib/ui/settings_v038.dart')
if "import 'data_health.dart';" not in settings:
    settings = settings.replace("import 'common.dart';", "import 'common.dart';\nimport 'data_health.dart';", 1)
backup_card_marker = r'''              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.content_copy_rounded,'''
backup_card_replacement = r'''              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.health_and_safety_outlined,
                    color: FinoraColors.income,
                  ),
                  title: const Text(
                    'Diagnóstico dos dados',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Verifica SQLite, vínculos e consistência antes de qualquer recuperação',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    PremiumRoute(page: const DataHealthScreen()),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.content_copy_rounded,'''
if backup_card_marker not in settings:
    raise RuntimeError('Backup card marker não encontrado')
settings = settings.replace(backup_card_marker, backup_card_replacement, 1)
write('lib/ui/settings_v038.dart', settings)

# ---------------------------------------------------------------------------
# Versionamento e changelog.
# ---------------------------------------------------------------------------
replace_once('pubspec.yaml', 'version: 0.5.0+18', 'version: 0.5.2+20')
write('lib/app_info.dart', "const finoraVersion = '0.5.2';\n")

changelog = read('CHANGELOG.md')
if not changelog.startswith('## v0.5.2'):
    changelog = r'''## v0.5.2 — Stateful Copilot + Stability Pack

### v0.5.1 incorporada
+- conversa da Finora passa a persistir localmente no FinanceData/SQLite e no backup;
+- troca de aba e rotação deixam de destruir o estado da IA graças ao shell com IndexedStack;
+- rascunho, modo Conversar/Registrar e clarificação pendente são restaurados;
+- virada de mês ganha aviso explícito e atalho para o mês anterior;
+- Movimentações passa a oferecer pesquisa em todos os meses;
+- novo Diagnóstico dos dados verifica SQLite, referências órfãs, IDs, snapshots e valores inválidos;
+- orçamento mostra percentual usado, valor restante e projeção pelo ritmo atual.

### v0.5.2
+- histórico persistido passa a alimentar a continuidade real das conversas;
+- Copilot local ganha resposta determinística de insights sem exigir Gemini;
+- novo motor de insights destaca atrasos, próximos 7 dias, aceleração de despesas, concentração por categoria, risco de orçamento e uso alto do cartão;
+- tela inicial exibe até três insights relevantes do período;
+- chat fica mais resistente a teclado/orientação e reduz elementos secundários em altura compacta;
+- sessão do chat é limitada e normalizada para evitar crescimento indefinido do estado.

''' + changelog
write('CHANGELOG.md', changelog)

# ---------------------------------------------------------------------------
# Testes de regressão da sessão/diagnóstico/insights/compatibilidade.
# ---------------------------------------------------------------------------
write(
    'test/v052_stateful_copilot_test.dart',
    r'''import 'dart:convert';

import 'package:finora/models.dart';
import 'package:finora/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  FinanceStore baseStore() {
    final store = FinanceStore();
    store.data.accounts.add(
      AccountItem(
        id: 'account-1',
        name: 'Principal',
        type: 'Conta',
        balance: 2500,
      ),
    );
    return store;
  }

  test('sessão do Copilot sobrevive a encode/decode completo', () {
    final store = baseStore();
    store.saveCopilotSession(
      messages: [
        CopilotChatMessageItem(
          id: 'm1',
          user: true,
          text: 'Quanto posso gastar?',
          createdAt: DateTime(2026, 9, 1, 12),
        ),
        CopilotChatMessageItem(
          id: 'm2',
          user: false,
          text: 'Você tem um valor disponível.',
          followUps: const ['Ver planejamento'],
          action: 'showPlanning',
          createdAt: DateTime(2026, 9, 1, 12, 1),
        ),
      ],
      draft: 'e no mês passado?',
      mode: 'transaction',
      pendingTransaction: 'gastei 30 de gasolina',
    );

    final restored = FinanceData.fromJson(
      Map<String, dynamic>.from(jsonDecode(store.data.encode()) as Map),
    );

    expect(restored.copilotChat, hasLength(2));
    expect(restored.copilotChat.last.action, 'showPlanning');
    expect(restored.copilotDraft, 'e no mês passado?');
    expect(restored.copilotMode, 'transaction');
    expect(restored.copilotPendingTransaction, 'gastei 30 de gasolina');
  });

  test('dados antigos sem campos de chat continuam compatíveis', () {
    final old = <String, dynamic>{
      'darkMode': true,
      'accounts': <dynamic>[],
      'cards': <dynamic>[],
      'transactions': <dynamic>[],
      'planned': <dynamic>[],
      'budgets': <dynamic>[],
      'goals': <dynamic>[],
      'reserves': <dynamic>[],
      'investments': <dynamic>[],
      'recurringRules': <dynamic>[],
      'installmentPlans': <dynamic>[],
      'categories': <dynamic>[],
      'snapshots': <dynamic>[],
    };

    final restored = FinanceData.fromJson(old);
    expect(restored.copilotChat, isEmpty);
    expect(restored.copilotDraft, isEmpty);
    expect(restored.copilotMode, 'chat');
  });

  test('histórico do Copilot é limitado às 120 mensagens mais recentes', () {
    final store = baseStore();
    final messages = List.generate(
      150,
      (index) => CopilotChatMessageItem(
        id: '$index',
        user: index.isEven,
        text: 'mensagem $index',
        createdAt: DateTime(2026, 9, 1).add(Duration(minutes: index)),
      ),
    );

    store.saveCopilotSession(
      messages: messages,
      draft: '',
      mode: 'chat',
    );

    expect(store.data.copilotChat, hasLength(120));
    expect(store.data.copilotChat.first.text, 'mensagem 30');
    expect(store.data.copilotChat.last.text, 'mensagem 149');
  });

  test('limpar conversa não altera dados financeiros', () {
    final store = baseStore();
    store.saveCopilotSession(
      messages: [
        CopilotChatMessageItem(
          id: 'm1',
          user: true,
          text: 'teste',
          createdAt: DateTime.now(),
        ),
      ],
      draft: 'rascunho',
      mode: 'chat',
    );

    store.clearCopilotSession();

    expect(store.data.copilotChat, isEmpty);
    expect(store.data.accounts.single.balance, 2500);
  });

  test('diagnóstico detecta referência órfã sem modificar o estado', () {
    final store = baseStore();
    store.data.transactions.add(
      TransactionItem(
        id: 'bad',
        type: TransactionType.expense,
        title: 'Órfã',
        category: 'Outros',
        amount: 10,
        date: DateTime.now(),
        account: 'Conta inexistente',
      ),
    );

    final before = store.data.encode();
    final issues = store.dataHealthIssues;

    expect(issues.any((issue) => issue.contains('conta inexistente')), isTrue);
    expect(store.data.encode(), before);
  });

  test('insights são determinísticos e não alteram finanças', () {
    final store = baseStore();
    final now = DateTime.now();
    store.data.budgets.add(
      BudgetItem(id: 'b1', category: 'Alimentação', limit: 100),
    );
    store.data.transactions.add(
      TransactionItem(
        id: 'food',
        type: TransactionType.expense,
        title: 'Mercado',
        category: 'Alimentação',
        amount: 90,
        date: now,
        account: 'Principal',
      ),
    );
    final before = store.data.encode();

    final insights = store.smartInsights;

    expect(insights, isNotEmpty);
    expect(store.data.encode(), before);
  });
}
''',
)

print('Finora v0.5.2 patch aplicado com sucesso.')
