from pathlib import Path


def read(path):
    return Path(path).read_text(encoding='utf-8')


def write(path, text):
    Path(path).write_text(text, encoding='utf-8')


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected 1 occurrence, found {count}')
    return text.replace(old, new, 1)


# models.dart -----------------------------------------------------------------
p = 'lib/models.dart'
s = read(p)

memory_model = r'''class CopilotMemoryItem {
  final String id;
  String label;
  String value;
  DateTime updatedAt;

  CopilotMemoryItem({
    required this.id,
    required this.label,
    required this.value,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'value': value,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CopilotMemoryItem.fromJson(Map<String, dynamic> j) =>
      CopilotMemoryItem(
        id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: j['label'] as String? ?? 'Memória',
        value: j['value'] as String? ?? '',
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

'''
s = replace_once(s, 'class TransactionItem {', memory_model + 'class TransactionItem {', 'insert memory model')

s = replace_once(
    s,
    '  String primaryGoal;\n  DateTime? trackingMonth;',
    '  String primaryGoal;\n  bool copilotMemoryEnabled;\n  final List<CopilotMemoryItem> copilotMemories;\n  DateTime? trackingMonth;',
    'FinanceData fields',
)
s = replace_once(
    s,
    '    required this.primaryGoal,\n    required this.trackingMonth,',
    '    required this.primaryGoal,\n    required this.copilotMemoryEnabled,\n    required this.copilotMemories,\n    required this.trackingMonth,',
    'FinanceData ctor',
)
s = replace_once(
    s,
    "        'primaryGoal': primaryGoal,\n        'trackingMonth': trackingMonth?.toIso8601String(),",
    "        'primaryGoal': primaryGoal,\n        'copilotMemoryEnabled': copilotMemoryEnabled,\n        'copilotMemories': copilotMemories.map((e) => e.toJson()).toList(),\n        'trackingMonth': trackingMonth?.toIso8601String(),",
    'FinanceData toJson',
)
s = replace_once(
    s,
    "        primaryGoal: j['primaryGoal'] as String? ?? 'Controlar gastos',\n        trackingMonth:",
    "        primaryGoal: j['primaryGoal'] as String? ?? 'Controlar gastos',\n        copilotMemoryEnabled: j['copilotMemoryEnabled'] as bool? ?? true,\n        copilotMemories: ((j['copilotMemories'] as List?) ?? [])\n            .whereType<Map>()\n            .map((e) => CopilotMemoryItem.fromJson(Map<String, dynamic>.from(e)))\n            .where((e) => e.value.trim().isNotEmpty)\n            .take(40)\n            .toList(),\n        trackingMonth:",
    'FinanceData fromJson',
)
write(p, s)

# store_backup.dart ------------------------------------------------------------
p = 'lib/store_backup.dart'
s = read(p)
s = replace_once(
    s,
    "      primaryGoal: 'Controlar gastos',\n      trackingMonth: null,",
    "      primaryGoal: 'Controlar gastos',\n      copilotMemoryEnabled: true,\n      copilotMemories: [],\n      trackingMonth: null,",
    'emptyData copilot',
)
s = replace_once(
    s,
    "    primaryGoal: 'Planejar melhor',\n    trackingMonth:",
    "    primaryGoal: 'Planejar melhor',\n    copilotMemoryEnabled: true,\n    copilotMemories: [],\n    trackingMonth:",
    'demoData copilot',
)
write(p, s)

# store_entities.dart ----------------------------------------------------------
p = 'lib/store_entities.dart'
s = read(p)
memory_methods = r'''
  void setCopilotMemoryEnabled(bool value) {
    if (data.copilotMemoryEnabled == value) return;
    data.copilotMemoryEnabled = value;
    commit();
  }

  bool rememberCopilot(String label, String value) {
    final cleanLabel = label.trim();
    final cleanValue = value.trim();
    if (cleanLabel.isEmpty || cleanValue.isEmpty) return false;

    final normalized = _normalizedName(cleanLabel);
    final existing = data.copilotMemories.where(
      (item) => _normalizedName(item.label) == normalized,
    );
    if (existing.isNotEmpty) {
      existing.first
        ..label = cleanLabel.substring(0, cleanLabel.length.clamp(0, 60))
        ..value = cleanValue.substring(0, cleanValue.length.clamp(0, 240))
        ..updatedAt = DateTime.now();
    } else {
      if (data.copilotMemories.length >= 40) {
        data.copilotMemories.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        data.copilotMemories.removeAt(0);
      }
      data.copilotMemories.add(
        CopilotMemoryItem(
          id: FinanceStore.newId(),
          label: cleanLabel.substring(0, cleanLabel.length.clamp(0, 60)),
          value: cleanValue.substring(0, cleanValue.length.clamp(0, 240)),
          updatedAt: DateTime.now(),
        ),
      );
    }
    commit();
    return true;
  }

  bool updateCopilotMemory(
    CopilotMemoryItem item,
    String label,
    String value,
  ) {
    final cleanLabel = label.trim();
    final cleanValue = value.trim();
    if (cleanLabel.isEmpty || cleanValue.isEmpty) return false;
    item
      ..label = cleanLabel.substring(0, cleanLabel.length.clamp(0, 60))
      ..value = cleanValue.substring(0, cleanValue.length.clamp(0, 240))
      ..updatedAt = DateTime.now();
    commit();
    return true;
  }

  void deleteCopilotMemory(String id) {
    final before = data.copilotMemories.length;
    data.copilotMemories.removeWhere((item) => item.id == id);
    if (data.copilotMemories.length != before) commit();
  }

  void clearCopilotMemories() {
    if (data.copilotMemories.isEmpty) return;
    data.copilotMemories.clear();
    commit();
  }
'''
s = replace_once(
    s,
    '  String _normalizedName(String value) => value.trim().toLowerCase();\n',
    '  String _normalizedName(String value) => value.trim().toLowerCase();\n' + memory_methods,
    'store copilot methods',
)
write(p, s)

# finance_ai.dart --------------------------------------------------------------
p = 'lib/ai/finance_ai.dart'
s = read(p)
s = replace_once(s, "import 'gemini_service.dart';", "import 'gemini_service.dart';\nimport 'copilot.dart';", 'copilot import')
s = replace_once(
    s,
    '  final bool local;\n\n  const AiAssistantReply({',
    '  final bool local;\n  final CopilotActionProposal? proposal;\n  final CopilotMemoryCandidate? memory;\n\n  const AiAssistantReply({',
    'reply fields',
)
s = replace_once(
    s,
    '    this.actionLabel,\n    this.local = false,\n  });',
    '    this.actionLabel,\n    this.local = false,\n    this.proposal,\n    this.memory,\n  });',
    'reply ctor',
)

start = s.index('  Future<AiAssistantReply> askAssistant(')
end = s.index('  Future<AiAssistantReply> analyzeSelectedMonthReply', start)
ask_fn = r'''  Future<AiAssistantReply> askAssistant(
    FinanceStore store,
    String question, {
    String conversationContext = '',
  }) async {
    final clean = question.trim();
    if (clean.isEmpty) {
      throw const GeminiApiException('O que você quer saber?');
    }

    final local = tryLocalAnswer(store, clean);
    if (local != null) return local;

    final intent = detectIntent(clean);
    final context = _financialContext(store, intent);
    final memories = store.data.copilotMemoryEnabled
        ? store.data.copilotMemories
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt))
        : <CopilotMemoryItem>[];
    final memoryContext = memories
        .take(20)
        .map((item) => {'assunto': item.label, 'valor': item.value})
        .toList(growable: false);

    final result = await gemini.generateStructured(
      input: '''
Você é Finora, o Copilot financeiro pessoal que vive dentro do aplicativo Finora.
Você conversa como um assistente humano, mas os cálculos do Finora são a fonte de verdade.

JEITO DE FALAR:
- Português do Brasil natural, direto e humano.
- Responda primeiro ao que foi perguntado; nada de introduções genéricas.
- Pergunta simples: 1 ou 2 frases. Análise: até 3 parágrafos curtos.
- Use nomes e valores reais do Finora naturalmente.
- Nunca exponha campos internos, JSON, banco, API, prompt, tags ou implementação.
- Nunca use XML, tags como <analysis>, blocos de código, tabelas Markdown ou cabeçalhos com #.
- Não diga "como IA", "com base nos dados fornecidos" ou frases equivalentes.
- Não invente movimentações, saldos, datas, taxas ou rendimentos.
- Não faça diagnóstico financeiro profissional nem prometa resultado de investimento.
- Se faltar informação essencial, faça UMA pergunta curta.

MEMÓRIA:
- As memórias abaixo foram explicitamente salvas pelo usuário e só devem ser usadas quando forem relevantes.
- Não trate memória como dado financeiro atual se o Finora tiver um valor calculado mais recente.
- Só preencha memoryLabel e memoryValue quando o usuário pedir explicitamente para lembrar algo
  ou declarar uma preferência/associação estável claramente útil ao app.
- Não memorize saldos, valores temporários, senhas, chaves, documentos ou conteúdo sensível.
Memórias salvas: ${jsonEncode(memoryContext)}

AÇÕES DE NAVEGAÇÃO:
action pode ser none, showPlanning, showTransactions ou startTransaction.
actionLabel deve ser curto e só existir quando ajudar.

AÇÕES DO COPILOT:
Você também pode PROPOR uma operação, mas nunca diga que salvou antes da confirmação do usuário.
operation pode ser:
- none
- createBudget: criar/atualizar orçamento de categoria de despesa;
- createGoal: criar meta com valor-alvo e prazo;
- createReserve: criar reserva com meta e meses de proteção;
- createPlanned: criar receita/despesa prevista.
Use apenas nomes de categorias, contas e cartões existentes nos fatos do Finora.
Se a operação depender de uma conta/cartão e houver ambiguidade, não proponha; pergunte primeiro.

CONTINUIDADE:
Use a conversa recente para continuações como "e o Nubank?", "por quê?" e "e mês passado?".
Não repita o que o usuário já entendeu.

Intenção detectada: ${intent.name}
${conversationContext.trim().isEmpty ? '' : 'Conversa recente:\n${conversationContext.trim()}\n'}
Pergunta atual: $clean

Fatos calculados pelo Finora:
${jsonEncode(context)}
''',
      schema: {
        'type': 'object',
        'properties': {
          'message': {'type': 'string'},
          'followUps': {
            'type': 'array',
            'items': {'type': 'string'},
            'maxItems': 3,
          },
          'action': {
            'type': 'string',
            'enum': [
              'none',
              'showPlanning',
              'showTransactions',
              'startTransaction',
            ],
          },
          'actionLabel': {'type': ['string', 'null']},
          'operation': {
            'type': 'string',
            'enum': [
              'none',
              'createBudget',
              'createGoal',
              'createReserve',
              'createPlanned',
            ],
          },
          'operationTitle': {'type': ['string', 'null']},
          'operationAmount': {'type': ['number', 'null']},
          'operationCategory': {'type': ['string', 'null']},
          'operationDate': {'type': ['string', 'null']},
          'operationTransactionType': {
            'type': ['string', 'null'],
            'enum': ['income', 'expense', null],
          },
          'operationPaymentKind': {
            'type': ['string', 'null'],
            'enum': ['account', 'card', null],
          },
          'operationSourceName': {'type': ['string', 'null']},
          'operationCardId': {'type': ['string', 'null']},
          'operationMonths': {'type': ['number', 'null']},
          'operationDeadline': {'type': ['string', 'null']},
          'memoryLabel': {'type': ['string', 'null']},
          'memoryValue': {'type': ['string', 'null']},
        },
        'required': [
          'message',
          'followUps',
          'action',
          'actionLabel',
          'operation',
          'operationTitle',
          'operationAmount',
          'operationCategory',
          'operationDate',
          'operationTransactionType',
          'operationPaymentKind',
          'operationSourceName',
          'operationCardId',
          'operationMonths',
          'operationDeadline',
          'memoryLabel',
          'memoryValue',
        ],
      },
      maxOutputTokens: 850,
    );

    final message = GeminiService.cleanAssistantText(
      result['message']?.toString() ?? '',
    );
    if (message.isEmpty) {
      throw const GeminiApiException('Não consegui formular uma resposta agora.');
    }

    final memoryLabel = _cleanNullable(result['memoryLabel']?.toString());
    final memoryValue = _cleanNullable(result['memoryValue']?.toString());
    final memory = memoryLabel != null && memoryValue != null
        ? CopilotMemoryCandidate(
            label: _truncate(memoryLabel, 60),
            value: _truncate(memoryValue, 240),
          )
        : null;

    return AiAssistantReply(
      message: message,
      followUps: _stringList(result['followUps'], max: 3)
          .map(GeminiService.cleanAssistantText)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      action: _parseAction(result['action']?.toString()),
      actionLabel: _cleanNullable(result['actionLabel']?.toString()),
      proposal: _proposalFromResult(store, result),
      memory: memory,
    );
  }

'''
s = s[:start] + ask_fn + s[end:]

s = replace_once(
    s,
    '  AiAssistantReply? tryLocalAnswer(FinanceStore store, String question) {\n    final clean = _fold(question);',
    "  AiAssistantReply? tryLocalAnswer(FinanceStore store, String question) {\n    final query = const FinancialQueryEngine().answer(store, question);\n    if (query != null) {\n      return AiAssistantReply(\n        message: query.message,\n        followUps: query.followUps,\n        local: true,\n      );\n    }\n\n    final clean = _fold(question);",
    'local query engine',
)

proposal_helper = r'''  CopilotActionProposal? _proposalFromResult(
    FinanceStore store,
    Map<String, dynamic> result,
  ) {
    final operation = result['operation']?.toString() ?? 'none';
    if (operation == 'none') return null;
    final amount = (result['operationAmount'] as num?)?.toDouble() ?? 0;
    if (!amount.isFinite || amount <= 0) return null;

    final title = _truncate(
      result['operationTitle']?.toString().trim() ?? '',
      120,
    );
    final requestedCategory = result['operationCategory']?.toString() ?? '';

    if (operation == 'createBudget') {
      final category = _resolveCategory(store.expenseCategories, requestedCategory);
      return CopilotActionProposal(
        type: CopilotActionType.createBudget,
        title: 'Orçamento de $category',
        summary: 'Limite mensal de ${_money(amount)} para $category',
        amount: amount,
        category: category,
      );
    }

    if (operation == 'createGoal') {
      final cleanTitle = title.isEmpty ? 'Nova meta' : title;
      final deadline = DateTime.tryParse(
        result['operationDeadline']?.toString() ?? '',
      );
      return CopilotActionProposal(
        type: CopilotActionType.createGoal,
        title: cleanTitle,
        summary: 'Meta de ${_money(amount)}${deadline == null ? '' : ' até ${_dateOnly(deadline)}'}',
        amount: amount,
        deadline: deadline,
      );
    }

    if (operation == 'createReserve') {
      final cleanTitle = title.isEmpty ? 'Reserva de emergência' : title;
      final months = ((result['operationMonths'] as num?)?.toInt() ?? 6).clamp(1, 60);
      return CopilotActionProposal(
        type: CopilotActionType.createReserve,
        title: cleanTitle,
        summary: 'Meta de ${_money(amount)} para $months meses de proteção',
        amount: amount,
        months: months,
      );
    }

    if (operation == 'createPlanned') {
      final type = result['operationTransactionType']?.toString() == 'income'
          ? TransactionType.income
          : TransactionType.expense;
      final requestedKind = result['operationPaymentKind']?.toString() == 'card'
          ? PaymentKind.card
          : PaymentKind.account;
      final paymentKind = type == TransactionType.income
          ? PaymentKind.account
          : requestedKind;
      final date = DateTime.tryParse(result['operationDate']?.toString() ?? '');
      if (date == null || date.year < 2020 || date.year > 2100) return null;
      final categories = type == TransactionType.income
          ? store.incomeCategories
          : store.expenseCategories;
      final category = _resolveCategory(categories, requestedCategory);
      String? source;
      String? cardId;
      if (paymentKind == PaymentKind.card) {
        cardId = _resolveCardId(
          store,
          result['operationCardId']?.toString() ?? '',
          result['operationSourceName']?.toString() ?? '',
        );
        final card = store.findCard(cardId);
        if (card == null) return null;
        source = card.name;
      } else {
        source = _resolveAccount(
          store,
          result['operationSourceName']?.toString() ?? '',
        );
        if (source.isEmpty) return null;
      }
      final cleanTitle = title.isEmpty
          ? (type == TransactionType.income ? 'Receita prevista' : 'Despesa prevista')
          : title;
      return CopilotActionProposal(
        type: CopilotActionType.createPlanned,
        title: cleanTitle,
        summary: '${type == TransactionType.income ? 'Receber' : 'Pagar'} ${_money(amount)} em ${_dateOnly(date)}',
        amount: amount,
        category: category,
        date: date,
        transactionType: type,
        paymentKind: paymentKind,
        sourceName: source,
        cardId: cardId,
      );
    }

    return null;
  }

'''
s = replace_once(s, '  AiAssistantAction _parseAction(String? value) => switch (value) {', proposal_helper + '  AiAssistantAction _parseAction(String? value) => switch (value) {', 'proposal helper')
write(p, s)

# ai_assistant.dart ------------------------------------------------------------
p = 'lib/ui/ai_assistant.dart'
s = read(p)
s = replace_once(s, "import '../ai/finance_ai.dart';", "import '../ai/finance_ai.dart';\nimport '../ai/copilot.dart';", 'assistant copilot import')
s = replace_once(
    s,
    '  final AiTransactionSuggestion? suggestion;\n  final List<String> followUps;',
    '  final AiTransactionSuggestion? suggestion;\n  final CopilotActionProposal? proposal;\n  final List<String> followUps;',
    'chat proposal field',
)
s = replace_once(
    s,
    '    this.suggestion,\n    this.followUps = const [],',
    '    this.suggestion,\n    this.proposal,\n    this.followUps = const [],',
    'chat proposal ctor',
)

old_append = r'''  void _appendReply(AiAssistantReply reply) {
    setState(
      () => _messages.add(
        _ChatMessage(
          user: false,
          text: reply.message,
          followUps: reply.followUps,
          action: reply.action,
          actionLabel: reply.actionLabel,
        ),
      ),
    );
  }
'''
new_append = r'''  void _appendReply(AiAssistantReply reply) {
    final store = context.read<FinanceStore>();
    final memory = reply.memory;
    if (memory != null && store.data.copilotMemoryEnabled) {
      store.rememberCopilot(memory.label, memory.value);
    }
    setState(
      () => _messages.add(
        _ChatMessage(
          user: false,
          text: reply.message,
          proposal: reply.proposal,
          followUps: reply.followUps,
          action: reply.action,
          actionLabel: reply.actionLabel,
        ),
      ),
    );
  }
'''
s = replace_once(s, old_append, new_append, 'append reply')

proposal_handlers = r'''
  void _confirmProposal(_ChatMessage message) {
    final proposal = message.proposal;
    if (proposal == null || message.handled) return;
    final ok = proposal.apply(context.read<FinanceStore>());
    if (!ok) {
      _snack('Não consegui aplicar essa ação. Confira os dados e tente novamente.');
      return;
    }
    setState(() {
      message.handled = true;
      _messages.add(
        _ChatMessage(
          user: false,
          text: 'Pronto. A alteração foi aplicada ao Finora.',
          followUps: const ['Como isso afeta meu mês?', 'Ver planejamento'],
        ),
      );
    });
    _scrollToEnd();
  }

  void _discardProposal(_ChatMessage message) {
    if (message.handled) return;
    setState(() {
      message.handled = true;
      _messages.add(_ChatMessage(user: false, text: 'Certo, não alterei nada.'));
    });
    _scrollToEnd();
  }
'''
s = replace_once(s, '  void _discard(_ChatMessage message) {', proposal_handlers + '\n  void _discard(_ChatMessage message) {', 'proposal handlers')

s = replace_once(
    s,
    '                    onDiscard: () => _discard(message),\n                    onQuickReply: _send,',
    '                    onDiscard: () => _discard(message),\n                    onConfirmProposal: () => _confirmProposal(message),\n                    onDiscardProposal: () => _discardProposal(message),\n                    onQuickReply: _send,',
    'message callbacks',
)

s = replace_once(
    s,
    "          _chip(\n            Icons.add_card_rounded,\n            'Registrar',\n            enabled ? _startTransaction : null,\n          ),",
    "          _chip(\n            Icons.calculate_outlined,\n            'Simular compra',\n            enabled ? () => _askPreset('Posso comprar algo de R\\$ 1.000 à vista?') : null,\n          ),\n          _chip(\n            Icons.add_card_rounded,\n            'Registrar',\n            enabled ? _startTransaction : null,\n          ),",
    'simulation chip',
)

s = replace_once(
    s,
    '  final VoidCallback onDiscard;\n  final ValueChanged<String> onQuickReply;',
    '  final VoidCallback onDiscard;\n  final VoidCallback onConfirmProposal;\n  final VoidCallback onDiscardProposal;\n  final ValueChanged<String> onQuickReply;',
    'bubble proposal callbacks fields',
)
s = replace_once(
    s,
    '    required this.onDiscard,\n    required this.onQuickReply,',
    '    required this.onDiscard,\n    required this.onConfirmProposal,\n    required this.onDiscardProposal,\n    required this.onQuickReply,',
    'bubble proposal callbacks ctor',
)
s = replace_once(
    s,
    "              if (message.suggestion case final suggestion?) ...[\n                const SizedBox(height: 10),\n                _SuggestionCard(\n                  suggestion: suggestion,\n                  source: source ?? suggestion.accountName,\n                  handled: message.handled,\n                  onConfirm: onConfirm,\n                  onDiscard: onDiscard,\n                ),\n              ],",
    "              if (message.suggestion case final suggestion?) ...[\n                const SizedBox(height: 10),\n                _SuggestionCard(\n                  suggestion: suggestion,\n                  source: source ?? suggestion.accountName,\n                  handled: message.handled,\n                  onConfirm: onConfirm,\n                  onDiscard: onDiscard,\n                ),\n              ],\n              if (message.proposal case final proposal?) ...[\n                const SizedBox(height: 10),\n                _CopilotActionCard(\n                  proposal: proposal,\n                  handled: message.handled,\n                  onConfirm: onConfirmProposal,\n                  onDiscard: onDiscardProposal,\n                ),\n              ],",
    'render proposal',
)

action_card = r'''
class _CopilotActionCard extends StatelessWidget {
  final CopilotActionProposal proposal;
  final bool handled;
  final VoidCallback onConfirm;
  final VoidCallback onDiscard;

  const _CopilotActionCard({
    required this.proposal,
    required this.handled,
    required this.onConfirm,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (proposal.type) {
      CopilotActionType.createBudget => 'Orçamento',
      CopilotActionType.createGoal => 'Meta',
      CopilotActionType.createReserve => 'Reserva',
      CopilotActionType.createPlanned => 'Planejamento',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinoraColors.goldBright.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FinoraColors.goldBright.withValues(alpha: .24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                handled ? Icons.check_circle_rounded : Icons.auto_fix_high_rounded,
                color: handled ? FinoraColors.income : FinoraColors.goldBright,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  handled ? '$label aplicado' : 'Confirmar $label',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            proposal.title,
            style: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            proposal.summary,
            style: TextStyle(
              fontSize: 9,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (!handled) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onDiscard,
                    child: const Text('Cancelar'),
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
}

'''
s = replace_once(s, 'class _SuggestionCard extends StatelessWidget {', action_card + 'class _SuggestionCard extends StatelessWidget {', 'action card class')
write(p, s)

# ai_settings.dart -------------------------------------------------------------
p = 'lib/ui/ai_settings.dart'
s = read(p)
s = replace_once(s, "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:provider/provider.dart';", 'provider import')
s = replace_once(s, "import '../theme.dart';", "import '../theme.dart';\nimport '../store.dart';", 'store import')
s = replace_once(s, "import 'common.dart';", "import 'common.dart';\nimport 'copilot_memory.dart';", 'memory screen import')

memory_section = r'''          const SizedBox(height: 14),
          Text('COPILOT', style: eyebrowStyle(context)),
          const SizedBox(height: 7),
          SurfaceCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.psychology_alt_outlined,
                    color: FinoraColors.investment,
                  ),
                  title: const Text(
                    'Memória contextual',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${context.watch<FinanceStore>().data.copilotMemories.length} lembrança(s) salva(s) · você mantém o controle',
                    style: const TextStyle(fontSize: 8.5),
                  ),
                  value: context.watch<FinanceStore>().data.copilotMemoryEnabled,
                  onChanged: context.read<FinanceStore>().setCopilotMemoryEnabled,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.memory_rounded),
                  title: const Text(
                    'Ver e editar memória',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Revise, edite ou apague tudo o que o Copilot lembra',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    PremiumRoute(page: const CopilotMemoryScreen()),
                  ),
                ),
              ],
            ),
          ),
'''
s = replace_once(
    s,
    "          const SizedBox(height: 14),\n          Text('PRIVACIDADE', style: eyebrowStyle(context)),",
    memory_section + "          const SizedBox(height: 14),\n          Text('PRIVACIDADE', style: eyebrowStyle(context)),",
    'memory settings section',
)
write(p, s)

# version files ----------------------------------------------------------------
p = 'pubspec.yaml'
s = read(p).replace('version: 0.4.5+17', 'version: 0.5.0+18')
write(p, s)
p = 'lib/app_info.dart'
s = read(p).replace("const finoraVersion = '0.4.5';", "const finoraVersion = '0.5.0';")
write(p, s)

# changelog --------------------------------------------------------------------
p = 'CHANGELOG.md'
s = read(p)
entry = '''## v0.5.0 — Finora Copilot\n\n- Memória contextual persistente, opcional e totalmente editável pelo usuário.\n- Financial Query Engine local para análises rápidas sem depender do Gemini.\n- Simulador conversacional de compras à vista e parceladas usando projeções reais.\n- Ações do Copilot com confirmação para orçamentos, metas, reservas e previstos.\n- Memórias passam a integrar o estado SQLite/backup do Finora.\n- Mantém todas as correções de integridade e performance da v0.4.5.\n\n'''
if not s.startswith('## v0.5.0'):
    s = entry + s
write(p, s)

print('Finora v0.5.0 Copilot patch applied')
