import 'dart:convert';

import '../models.dart';
import '../store.dart';
import 'gemini_service.dart';

enum AiAssistantAction {
  none,
  showPlanning,
  showTransactions,
  startTransaction,
}

enum AiAssistantIntent {
  overview,
  balance,
  spending,
  cards,
  planning,
  comparison,
  transaction,
  general,
}

class AiAssistantReply {
  final String message;
  final List<String> followUps;
  final AiAssistantAction action;
  final String? actionLabel;
  final bool local;

  const AiAssistantReply({
    required this.message,
    this.followUps = const [],
    this.action = AiAssistantAction.none,
    this.actionLabel,
    this.local = false,
  });
}

class AiTransactionInterpretation {
  final AiTransactionSuggestion? suggestion;
  final String? clarification;
  final List<String> choices;

  const AiTransactionInterpretation._({
    this.suggestion,
    this.clarification,
    this.choices = const [],
  });

  const AiTransactionInterpretation.ready(AiTransactionSuggestion value)
      : this._(suggestion: value);

  const AiTransactionInterpretation.clarify(
    String question, {
    List<String> choices = const [],
  }) : this._(clarification: question, choices: choices);

  bool get needsClarification => suggestion == null;
}

class AiTransactionSuggestion {
  final TransactionType type;
  final double amount;
  final String title;
  final String category;
  final DateTime date;
  final PaymentKind paymentKind;
  final String accountName;
  final String? destinationAccountName;
  final String? cardId;
  final String note;
  final double confidence;
  final String reason;

  const AiTransactionSuggestion({
    required this.type,
    required this.amount,
    required this.title,
    required this.category,
    required this.date,
    required this.paymentKind,
    required this.accountName,
    required this.destinationAccountName,
    required this.cardId,
    required this.note,
    required this.confidence,
    required this.reason,
  });

  bool apply(FinanceStore store) {
    if (!amount.isFinite || amount <= 0) return false;
    if (type == TransactionType.transfer) {
      final destination = destinationAccountName;
      if (destination == null || destination.isEmpty) return false;
      return store.transfer(
        amount: amount,
        from: accountName,
        to: destination,
        date: date,
      );
    }

    final isCard =
        type == TransactionType.expense && paymentKind == PaymentKind.card;
    final card = isCard ? store.findCard(cardId) : null;
    final account = store.findAccount(accountName);
    if (isCard && card == null) return false;
    if (!isCard && account == null) return false;

    store.addTransaction(
      TransactionItem(
        id: FinanceStore.newId(),
        type: type,
        title: title,
        category: category,
        amount: amount,
        date: date,
        account: isCard ? card!.name : accountName,
        paymentKind: isCard ? PaymentKind.card : PaymentKind.account,
        cardId: isCard ? card!.id : null,
        note: note.isEmpty ? 'Criado via Finora IA' : '$note · Finora IA',
      ),
    );
    return true;
  }
}

class FinoraAiService {
  final GeminiService gemini;

  const FinoraAiService({this.gemini = const GeminiService()});

  Future<AiTransactionSuggestion> interpretTransaction(
    FinanceStore store,
    String input,
  ) async {
    final result = await interpretTransactionConversational(store, input);
    final suggestion = result.suggestion;
    if (suggestion != null) return suggestion;
    throw GeminiApiException(
      result.clarification ?? 'Preciso de mais uma informação para montar esse lançamento.',
    );
  }

  Future<AiTransactionInterpretation> interpretTransactionConversational(
    FinanceStore store,
    String input, {
    String conversationContext = '',
  }) async {
    final clean = input.trim();
    if (clean.isEmpty) {
      throw const GeminiApiException('Me diga o que você quer registrar.');
    }

    final accounts = store.data.accounts.map((e) => e.name).toList();
    final cards = store.data.cards
        .map((e) => {'id': e.id, 'name': e.name})
        .toList();
    final prompt = '''
Você interpreta lançamentos para o aplicativo financeiro Finora.
Seu trabalho é entender a fala natural do usuário e montar UM lançamento.

REGRAS IMPORTANTES:
- Nunca invente valor, conta ou cartão.
- Data ausente significa hoje.
- Categoria pode ser inferida usando somente a lista válida.
- Receita nunca usa cartão.
- Transferência exige origem e destino diferentes.
- Se houver MAIS DE UMA conta/cartão possível e o usuário não indicar qual usou,
  marque needsClarification=true e faça UMA pergunta curta e natural.
- Não peça informação que pode ser inferida com segurança.
- choices deve trazer no máximo 4 opções reais do Finora que respondam à pergunta.
- Quando needsClarification=true, os demais campos podem ser null.
- Quando needsClarification=false, devolva todos os campos necessários.
- reason deve ser uma frase curta em linguagem comum, sem termos técnicos.

Hoje: ${_dateOnly(DateTime.now())}
Contas válidas: ${jsonEncode(accounts)}
Cartões válidos: ${jsonEncode(cards)}
Categorias de despesa: ${jsonEncode(store.expenseCategories)}
Categorias de receita: ${jsonEncode(store.incomeCategories)}
${conversationContext.trim().isEmpty ? '' : 'Contexto da conversa: ${conversationContext.trim()}'}

Mensagem do usuário:
$clean
''';

    final result = await gemini.generateStructured(
      input: prompt,
      schema: {
        'type': 'object',
        'properties': {
          'needsClarification': {'type': 'boolean'},
          'clarificationQuestion': {'type': 'string'},
          'choices': {
            'type': 'array',
            'items': {'type': 'string'},
            'maxItems': 4,
          },
          'type': {
            'type': ['string', 'null'],
            'enum': ['income', 'expense', 'transfer', null],
          },
          'amount': {'type': ['number', 'null']},
          'title': {'type': ['string', 'null']},
          'category': {'type': ['string', 'null']},
          'date': {'type': ['string', 'null']},
          'paymentKind': {
            'type': ['string', 'null'],
            'enum': ['account', 'card', null],
          },
          'accountName': {'type': ['string', 'null']},
          'destinationAccountName': {'type': ['string', 'null']},
          'cardId': {'type': ['string', 'null']},
          'note': {'type': ['string', 'null']},
          'confidence': {
            'type': ['number', 'null'],
            'minimum': 0,
            'maximum': 1,
          },
          'reason': {'type': ['string', 'null']},
        },
        'required': [
          'needsClarification',
          'clarificationQuestion',
          'choices',
          'type',
          'amount',
          'title',
          'category',
          'date',
          'paymentKind',
          'accountName',
          'destinationAccountName',
          'cardId',
          'note',
          'confidence',
          'reason',
        ],
      },
    );

    if (result['needsClarification'] == true) {
      final question = GeminiService.cleanAssistantText(
        result['clarificationQuestion']?.toString() ?? '',
      );
      final choices = _stringList(result['choices'], max: 4)
          .where((value) => _isKnownSource(store, value))
          .toList(growable: false);
      return AiTransactionInterpretation.clarify(
        question.isEmpty ? 'Qual conta ou cartão você usou?' : question,
        choices: choices,
      );
    }

    final type = switch (result['type']?.toString()) {
      'income' => TransactionType.income,
      'transfer' => TransactionType.transfer,
      _ => TransactionType.expense,
    };
    final amount = (result['amount'] as num?)?.toDouble() ?? 0;
    if (!amount.isFinite || amount <= 0) {
      return const AiTransactionInterpretation.clarify(
        'Qual foi o valor?',
      );
    }

    final requestedKind = result['paymentKind']?.toString() == 'card'
        ? PaymentKind.card
        : PaymentKind.account;
    final paymentKind =
        type == TransactionType.income || type == TransactionType.transfer
            ? PaymentKind.account
            : requestedKind;

    final accountName = _resolveAccount(
      store,
      result['accountName']?.toString() ?? '',
    );
    final destination = type == TransactionType.transfer
        ? _resolveAccount(
            store,
            result['destinationAccountName']?.toString() ?? '',
            excluding: accountName,
          )
        : null;
    final cardId = paymentKind == PaymentKind.card
        ? _resolveCardId(
            store,
            result['cardId']?.toString() ?? '',
            result['accountName']?.toString() ?? '',
          )
        : null;

    if (type == TransactionType.transfer &&
        (accountName.isEmpty || destination == null || destination.isEmpty)) {
      return AiTransactionInterpretation.clarify(
        accountName.isEmpty
            ? 'De qual conta o dinheiro vai sair?'
            : 'Para qual conta o dinheiro vai?',
        choices: store.data.accounts
            .where((item) => item.name != accountName)
            .map((item) => item.name)
            .take(4)
            .toList(),
      );
    }
    if (paymentKind == PaymentKind.account && accountName.isEmpty) {
      return AiTransactionInterpretation.clarify(
        'Qual conta você usou?',
        choices: store.data.accounts.map((e) => e.name).take(4).toList(),
      );
    }
    if (paymentKind == PaymentKind.card && cardId == null) {
      return AiTransactionInterpretation.clarify(
        'Qual cartão você usou?',
        choices: store.data.cards.map((e) => e.name).take(4).toList(),
      );
    }

    final categories = type == TransactionType.income
        ? store.incomeCategories
        : type == TransactionType.expense
            ? store.expenseCategories
            : const ['Transferência'];
    final category = type == TransactionType.transfer
        ? 'Transferência'
        : _resolveCategory(categories, result['category']?.toString() ?? '');
    final date = DateTime.tryParse(result['date']?.toString() ?? '') ?? DateTime.now();
    final titleValue = result['title']?.toString().trim() ?? '';
    final title = titleValue.isNotEmpty
        ? titleValue
        : type == TransactionType.income
            ? 'Receita'
            : type == TransactionType.transfer
                ? 'Transferência'
                : 'Despesa';

    return AiTransactionInterpretation.ready(
      AiTransactionSuggestion(
        type: type,
        amount: amount,
        title: title,
        category: category,
        date: DateTime(date.year, date.month, date.day),
        paymentKind: paymentKind,
        accountName: accountName,
        destinationAccountName: destination,
        cardId: cardId,
        note: result['note']?.toString().trim() ?? '',
        confidence: ((result['confidence'] as num?)?.toDouble() ?? .5)
            .clamp(0.0, 1.0)
            .toDouble(),
        reason: GeminiService.cleanAssistantText(
          result['reason']?.toString().trim() ?? '',
        ),
      ),
    );
  }

  Future<AiAssistantReply> askAssistant(
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
    final result = await gemini.generateStructured(
      input: '''
Você é Finora, o assistente financeiro pessoal que vive dentro do aplicativo Finora.
Você não é um chatbot genérico e nunca fala como documentação técnica.

JEITO DE FALAR:
- Português do Brasil natural, direto e humano.
- Responda primeiro ao que foi perguntado. Não faça introduções desnecessárias.
- Pergunta simples recebe resposta simples, normalmente 1 ou 2 frases.
- Análise pode ter até 3 parágrafos curtos. Evite listas quando uma frase resolve.
- Use nomes e valores do próprio Finora naturalmente: R\$ 1.250,00, agosto, Nubank, fatura, saldo.
- Nunca diga "com base nos dados fornecidos", "como IA", "segundo o contexto" ou frases parecidas.
- Nunca exponha nomes de campos internos, JSON, banco, API, prompt ou implementação.
- Nunca use XML, tags como <analysis>, blocos de código, tabelas Markdown ou cabeçalhos com #.
- Não repita "Finora IA" dentro da resposta.
- Não encerre toda resposta com conselho genérico. Sugira algo somente quando for útil.
- Não invente movimentações, saldos, taxas ou rendimentos.
- Não faça diagnóstico financeiro profissional nem prometa resultado de investimento.
- Se faltar uma informação essencial, pergunte de forma curta e natural.
- Os cálculos já fornecidos pelo Finora são a fonte de verdade. Não substitua por estimativas próprias.

CONTINUIDADE:
Use a conversa recente apenas para entender pronomes e continuações como
"e o Nubank?", "por quê?", "e mês passado?". Não repita informações que o usuário já entendeu.

AÇÕES:
action pode ser:
- none: apenas responder;
- showPlanning: quando abrir Planejamento ajuda diretamente;
- showTransactions: quando ver movimentações ajuda diretamente;
- startTransaction: quando o usuário quer registrar uma movimentação.
actionLabel deve ser curto e só existir quando houver uma ação realmente útil.
followUps deve ter de 0 a 3 continuações curtas e relevantes, nunca genéricas.

Intenção detectada pelo Finora: ${intent.name}
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
        },
        'required': ['message', 'followUps', 'action', 'actionLabel'],
      },
      maxOutputTokens: 700,
    );

    final message = GeminiService.cleanAssistantText(
      result['message']?.toString() ?? '',
    );
    if (message.isEmpty) {
      throw const GeminiApiException('Não consegui formular uma resposta agora.');
    }

    return AiAssistantReply(
      message: message,
      followUps: _stringList(result['followUps'], max: 3)
          .map(GeminiService.cleanAssistantText)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      action: _parseAction(result['action']?.toString()),
      actionLabel: _cleanNullable(result['actionLabel']?.toString()),
    );
  }

  Future<AiAssistantReply> analyzeSelectedMonthReply(FinanceStore store) =>
      askAssistant(
        store,
        'Como está meu mês? Me diga só o que realmente merece atenção.',
      );

  Future<String> analyzeSelectedMonth(FinanceStore store) async =>
      (await analyzeSelectedMonthReply(store)).message;

  Future<String> ask(FinanceStore store, String question) async =>
      (await askAssistant(store, question)).message;

  AiAssistantReply? tryLocalAnswer(FinanceStore store, String question) {
    final clean = _fold(question);
    final selected = store.selectedMonth;

    if (_hasAny(clean, ['patrimonio', 'patrimônio', 'quanto tenho no total'])) {
      return AiAssistantReply(
        message: 'Seu patrimônio no Finora está em ${_money(store.netWorth)}.',
        followUps: const ['Como esse valor está dividido?', 'E comparado ao mês passado?'],
        local: true,
      );
    }

    if (_hasAny(clean, [
      'quanto posso gastar',
      'disponivel para gastar',
      'disponível para gastar',
      'quanto ainda posso gastar',
    ])) {
      final payable = store.plannedPayableForMonth(selected);
      final receivable = store.plannedReceivableForMonth(selected);
      var message = 'Hoje você tem ${_money(store.availableToSpend)} disponíveis para gastar.';
      if (payable > 0 || receivable > 0) {
        message +=
            ' Neste mês ainda há ${_money(payable)} previstos para sair e ${_money(receivable)} para entrar.';
      }
      return AiAssistantReply(
        message: message,
        followUps: const ['Quais são as próximas contas?', 'Onde estou gastando mais?'],
        action: payable > 0 ? AiAssistantAction.showPlanning : AiAssistantAction.none,
        actionLabel: payable > 0 ? 'Ver planejamento' : null,
        local: true,
      );
    }

    for (final account in store.data.accounts) {
      final accountName = _fold(account.name);
      if (accountName.isNotEmpty &&
          clean.contains(accountName) &&
          _hasAny(clean, ['saldo', 'quanto tenho', 'quanto tem', 'valor'])) {
        return AiAssistantReply(
          message: '${account.name} está com ${_money(account.balance)}.',
          followUps: const ['Quanto posso gastar?', 'Ver minhas movimentações'],
          action: AiAssistantAction.showTransactions,
          actionLabel: 'Ver movimentações',
          local: true,
        );
      }
    }

    for (final card in store.data.cards) {
      final cardName = _fold(card.name);
      if (cardName.isEmpty || !clean.contains(cardName)) continue;
      if (_hasAny(clean, ['fatura', 'cartao', 'cartão', 'limite', 'quanto devo'])) {
        final invoice = store.invoiceOutstandingForMonth(card.id, selected);
        final availableLimit = (card.limit - card.used).clamp(0, double.infinity);
        return AiAssistantReply(
          message:
              'A fatura atual do ${card.name} está em ${_money(invoice)}. O limite disponível é ${_money(availableLimit.toDouble())}.',
          followUps: const ['O que mais pesou nessa fatura?', 'Comparar com o mês passado'],
          local: true,
        );
      }
    }

    if (_hasAny(clean, ['saldo total', 'saldo em contas', 'quanto tenho nas contas'])) {
      return AiAssistantReply(
        message: 'Você tem ${_money(store.cashBalance)} somando as contas.',
        followUps: const ['Como está dividido?', 'Quanto posso gastar?'],
        local: true,
      );
    }

    return null;
  }

  AiAssistantIntent detectIntent(String question) {
    final clean = _fold(question);
    if (_looksLikeTransaction(clean)) return AiAssistantIntent.transaction;
    if (_hasAny(clean, ['cartao', 'fatura', 'limite'])) return AiAssistantIntent.cards;
    if (_hasAny(clean, ['conta', 'saldo', 'patrimonio', 'quanto tenho'])) {
      return AiAssistantIntent.balance;
    }
    if (_hasAny(clean, ['planej', 'proxim', 'vence', 'vencimento', 'conta a pagar'])) {
      return AiAssistantIntent.planning;
    }
    if (_hasAny(clean, ['compar', 'mes passado', 'mês passado', 'julho', 'junho'])) {
      return AiAssistantIntent.comparison;
    }
    if (_hasAny(clean, ['gastei', 'gasto', 'despesa', 'categoria', 'onde estou gastando'])) {
      return AiAssistantIntent.spending;
    }
    if (_hasAny(clean, ['como estou', 'meu mes', 'meu mês', 'resumo', 'analise', 'análise'])) {
      return AiAssistantIntent.overview;
    }
    return AiAssistantIntent.general;
  }

  bool looksLikeTransactionRequest(String input) => _looksLikeTransaction(_fold(input));

  Map<String, dynamic> _financialContext(
    FinanceStore store,
    AiAssistantIntent intent,
  ) {
    final selected = store.selectedMonth;
    final base = <String, dynamic>{
      'mesSelecionado': '${selected.year}-${selected.month.toString().padLeft(2, '0')}',
      'hoje': _dateOnly(DateTime.now()),
      'disponivelParaGastar': store.availableToSpend,
    };

    if (intent == AiAssistantIntent.balance ||
        intent == AiAssistantIntent.overview ||
        intent == AiAssistantIntent.general) {
      base.addAll({
        'saldoEmContas': store.cashBalance,
        'reservas': store.reserveBalance,
        'investimentos': store.investmentBalance,
        'patrimonio': store.netWorth,
        'contas': store.data.accounts
            .map((e) => {'nome': e.name, 'saldo': e.balance, 'tipo': e.type})
            .toList(),
      });
    }

    if (intent == AiAssistantIntent.cards ||
        intent == AiAssistantIntent.overview ||
        intent == AiAssistantIntent.general) {
      base['cartoes'] = store.data.cards
          .map(
            (e) => {
              'nome': e.name,
              'limite': e.limit,
              'usado': e.used,
              'faturaAtual': store.invoiceOutstandingForMonth(e.id, selected),
              'limiteDisponivel': (e.limit - e.used).clamp(0, double.infinity),
            },
          )
          .toList();
    }

    if (intent == AiAssistantIntent.spending ||
        intent == AiAssistantIntent.comparison ||
        intent == AiAssistantIntent.overview ||
        intent == AiAssistantIntent.general) {
      base['historicoMensal'] = _monthHistory(store, selected);
      final recent = store.data.transactions.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      base['movimentacoesRecentes'] = recent.take(30).map((e) => {
            'tipo': e.type.name,
            'descricao': e.title,
            'categoria': e.category,
            'valor': e.amount,
            'data': _dateOnly(e.date),
            'origem': e.account,
          }).toList();
    }

    if (intent == AiAssistantIntent.planning ||
        intent == AiAssistantIntent.overview ||
        intent == AiAssistantIntent.general) {
      final upcoming = store.data.planned
          .where((e) => e.status == PlannedStatus.planned)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      base.addAll({
        'previstoParaReceberNoMes': store.plannedReceivableForMonth(selected),
        'previstoParaPagarNoMes': store.plannedPayableForMonth(selected),
        'quantidadeAtrasados': store.overduePlannedCount,
        'proximosCompromissos': upcoming.take(20).map((e) => {
              'tipo': e.type.name,
              'descricao': e.title,
              'categoria': e.category,
              'valor': e.amount,
              'data': _dateOnly(e.date),
              'origem': e.sourceName,
            }).toList(),
      });
    }

    return base;
  }

  List<Map<String, dynamic>> _monthHistory(FinanceStore store, DateTime selected) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < 4; i++) {
      final month = DateTime(selected.year, selected.month - i);
      final categoryMap = <String, double>{};
      for (final tx in store.transactionsForMonth(month)) {
        if (tx.type == TransactionType.expense) {
          categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
        }
      }
      result.add({
        'mes': '${month.year}-${month.month.toString().padLeft(2, '0')}',
        'receitas': store.incomeForMonth(month),
        'despesas': store.expenseForMonth(month),
        'resultado': store.incomeForMonth(month) - store.expenseForMonth(month),
        'gastosPorCategoria': categoryMap,
      });
    }
    return result;
  }

  AiAssistantAction _parseAction(String? value) => switch (value) {
        'showPlanning' => AiAssistantAction.showPlanning,
        'showTransactions' => AiAssistantAction.showTransactions,
        'startTransaction' => AiAssistantAction.startTransaction,
        _ => AiAssistantAction.none,
      };

  String? _cleanNullable(String? value) {
    if (value == null) return null;
    final clean = GeminiService.cleanAssistantText(value);
    return clean.isEmpty ? null : clean;
  }

  List<String> _stringList(dynamic raw, {required int max}) {
    if (raw is! List) return const [];
    return raw
        .whereType<Object>()
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .take(max)
        .toList(growable: false);
  }

  bool _isKnownSource(FinanceStore store, String value) {
    final clean = _fold(value);
    return store.data.accounts.any((e) => _fold(e.name) == clean) ||
        store.data.cards.any((e) => _fold(e.name) == clean);
  }

  bool _looksLikeTransaction(String clean) {
    final hasVerb = _hasAny(clean, [
      'gastei',
      'paguei',
      'comprei',
      'recebi',
      'transferi',
      'mandei',
      'enviei',
      'registra',
      'registre',
      'lanca',
      'lança',
      'adiciona',
      'adicione',
    ]);
    final hasValue = RegExp(r'\b\d+[\.,]?\d*\b').hasMatch(clean);
    return hasVerb && hasValue;
  }

  bool _hasAny(String source, List<String> terms) =>
      terms.any((term) => source.contains(_fold(term)));

  String _fold(String value) {
    var text = value.toLowerCase().trim();
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    replacements.forEach((from, to) => text = text.replaceAll(from, to));
    return text;
  }

  String _money(double value) {
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}R\$ ${buffer.toString()},${parts.last}';
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _resolveCategory(List<String> categories, String requested) {
    final clean = requested.trim().toLowerCase();
    for (final value in categories) {
      if (value.toLowerCase() == clean) return value;
    }
    for (final value in categories) {
      if (clean.isNotEmpty &&
          (value.toLowerCase().contains(clean) ||
              clean.contains(value.toLowerCase()))) {
        return value;
      }
    }
    return categories.contains('Outros') ? 'Outros' : categories.first;
  }

  String _resolveAccount(
    FinanceStore store,
    String requested, {
    String? excluding,
  }) {
    final candidates = store.data.accounts
        .where((e) => e.name != excluding)
        .map((e) => e.name)
        .toList();
    if (candidates.isEmpty) return '';
    final clean = requested.trim().toLowerCase();
    for (final value in candidates) {
      if (value.toLowerCase() == clean) return value;
    }
    for (final value in candidates) {
      if (clean.isNotEmpty && value.toLowerCase().contains(clean)) return value;
    }
    return candidates.length == 1 ? candidates.first : '';
  }

  String? _resolveCardId(
    FinanceStore store,
    String requestedId,
    String requestedName,
  ) {
    for (final card in store.data.cards) {
      if (card.id == requestedId) return card.id;
    }
    final clean = requestedName.trim().toLowerCase();
    for (final card in store.data.cards) {
      if (card.name.toLowerCase() == clean) return card.id;
    }
    for (final card in store.data.cards) {
      if (clean.isNotEmpty && card.name.toLowerCase().contains(clean)) {
        return card.id;
      }
    }
    return store.data.cards.length == 1 ? store.data.cards.first.id : null;
  }
}
