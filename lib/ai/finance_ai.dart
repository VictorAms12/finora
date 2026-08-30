import 'dart:convert';

import '../models.dart';
import '../store.dart';
import 'gemini_service.dart';

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

    final isCard = type == TransactionType.expense && paymentKind == PaymentKind.card;
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
    final clean = input.trim();
    if (clean.isEmpty) {
      throw const GeminiApiException('Descreva o lançamento que deseja registrar.');
    }

    final accounts = store.data.accounts.map((e) => e.name).toList();
    final cards = store.data.cards
        .map((e) => {'id': e.id, 'name': e.name})
        .toList();
    final prompt = '''
Você é o interpretador de lançamentos do aplicativo financeiro Finora.
Converta a frase do usuário em UM lançamento estruturado. Não invente contas,
cartões ou valores. Quando uma informação não estiver explícita, use a opção
mais provável somente se houver uma única opção válida. Para categoria, escolha
apenas uma das categorias fornecidas. Receitas nunca usam cartão. Transferências
precisam de conta de origem e destino. Datas devem ser ISO YYYY-MM-DD.

Hoje: ${_dateOnly(DateTime.now())}
Contas válidas: ${jsonEncode(accounts)}
Cartões válidos: ${jsonEncode(cards)}
Categorias de despesa: ${jsonEncode(store.expenseCategories)}
Categorias de receita: ${jsonEncode(store.incomeCategories)}

Frase do usuário:
$clean
''';

    final result = await gemini.generateStructured(
      input: prompt,
      schema: {
        'type': 'object',
        'properties': {
          'type': {
            'type': 'string',
            'enum': ['income', 'expense', 'transfer'],
          },
          'amount': {'type': 'number'},
          'title': {'type': 'string'},
          'category': {'type': 'string'},
          'date': {'type': 'string'},
          'paymentKind': {
            'type': 'string',
            'enum': ['account', 'card'],
          },
          'accountName': {'type': 'string'},
          'destinationAccountName': {
            'type': ['string', 'null'],
          },
          'cardId': {
            'type': ['string', 'null'],
          },
          'note': {'type': 'string'},
          'confidence': {
            'type': 'number',
            'minimum': 0,
            'maximum': 1,
          },
          'reason': {'type': 'string'},
        },
        'required': [
          'type',
          'amount',
          'title',
          'category',
          'date',
          'paymentKind',
          'accountName',
          'note',
          'confidence',
          'reason',
        ],
      },
    );

    final type = switch (result['type']?.toString()) {
      'income' => TransactionType.income,
      'transfer' => TransactionType.transfer,
      _ => TransactionType.expense,
    };
    final amount = (result['amount'] as num?)?.toDouble() ?? 0;
    if (!amount.isFinite || amount <= 0) {
      throw const GeminiApiException('Não consegui identificar um valor válido.');
    }

    final requestedKind = result['paymentKind']?.toString() == 'card'
        ? PaymentKind.card
        : PaymentKind.account;
    final paymentKind = type == TransactionType.income || type == TransactionType.transfer
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
        ? _resolveCardId(store, result['cardId']?.toString() ?? '', result['accountName']?.toString() ?? '')
        : null;

    if (type == TransactionType.transfer &&
        (accountName.isEmpty || destination == null || destination.isEmpty)) {
      throw const GeminiApiException(
        'Não consegui identificar as duas contas da transferência.',
      );
    }
    if (paymentKind == PaymentKind.account && accountName.isEmpty) {
      throw const GeminiApiException('Não consegui identificar a conta do lançamento.');
    }
    if (paymentKind == PaymentKind.card && cardId == null) {
      throw const GeminiApiException('Não consegui identificar o cartão do lançamento.');
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
    final title = (result['title']?.toString().trim().isNotEmpty ?? false)
        ? result['title'].toString().trim()
        : type == TransactionType.income
            ? 'Receita'
            : type == TransactionType.transfer
                ? 'Transferência'
                : 'Despesa';

    return AiTransactionSuggestion(
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
      reason: result['reason']?.toString().trim() ?? '',
    );
  }

  Future<String> analyzeSelectedMonth(FinanceStore store) {
    final context = _financialContext(store);
    return gemini.generateText(
      input: '''
Você é o Finora IA, um assistente de organização financeira pessoal. Analise
somente os números fornecidos. Não invente movimentações, taxas ou rendimentos.
Se houver pouca informação, diga isso claramente. Seja objetivo, em português
do Brasil. Destaque no máximo 4 pontos: evolução do mês, categorias relevantes,
compromissos próximos e uma ação prática de baixo risco. Não trate a resposta
como consultoria financeira profissional.

DADOS DO FINORA:
${jsonEncode(context)}
''',
      maxOutputTokens: 700,
    );
  }

  Future<String> ask(FinanceStore store, String question) {
    final clean = question.trim();
    if (clean.isEmpty) {
      throw const GeminiApiException('Digite uma pergunta sobre suas finanças.');
    }
    final context = _financialContext(store);
    return gemini.generateText(
      input: '''
Você é o Finora IA. Responda à pergunta usando EXCLUSIVAMENTE os dados abaixo.
Faça cálculos simples quando necessário, mas nunca invente informações. Caso a
pergunta não possa ser respondida com o contexto fornecido, explique o que falta.
Responda em português do Brasil, de forma curta e clara. Você não executa ações
financeiras e não deve afirmar que alterou dados.

PERGUNTA: $clean

DADOS DO FINORA:
${jsonEncode(context)}
''',
      maxOutputTokens: 850,
    );
  }

  Map<String, dynamic> _financialContext(FinanceStore store) {
    final selected = store.selectedMonth;
    final monthHistory = <Map<String, dynamic>>[];
    for (var i = 0; i < 4; i++) {
      final month = DateTime(selected.year, selected.month - i);
      final categoryMap = <String, double>{};
      for (final tx in store.transactionsForMonth(month)) {
        if (tx.type == TransactionType.expense) {
          categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
        }
      }
      monthHistory.add({
        'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
        'income': store.incomeForMonth(month),
        'expense': store.expenseForMonth(month),
        'balance': store.incomeForMonth(month) - store.expenseForMonth(month),
        'expensesByCategory': categoryMap,
      });
    }

    final recent = store.data.transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final upcoming = store.data.planned
        .where((e) => e.status == PlannedStatus.planned)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'selectedMonth': '${selected.year}-${selected.month.toString().padLeft(2, '0')}',
      'cashBalance': store.cashBalance,
      'reserveBalance': store.reserveBalance,
      'investmentBalance': store.investmentBalance,
      'netWorth': store.netWorth,
      'availableToSpend': store.availableToSpend,
      'accounts': store.data.accounts
          .map((e) => {'name': e.name, 'balance': e.balance, 'type': e.type})
          .toList(),
      'cards': store.data.cards
          .map(
            (e) => {
              'name': e.name,
              'limit': e.limit,
              'used': e.used,
              'currentInvoice': store.invoiceOutstandingForMonth(e.id, selected),
            },
          )
          .toList(),
      'months': monthHistory,
      'plannedReceivable': store.plannedReceivableForMonth(selected),
      'plannedPayable': store.plannedPayableForMonth(selected),
      'overduePlannedCount': store.overduePlannedCount,
      // Limita o contexto enviado: não manda backup, snapshots ou notas privadas.
      'recentTransactions': recent.take(35).map((e) => {
            'type': e.type.name,
            'title': e.title,
            'category': e.category,
            'amount': e.amount,
            'date': _dateOnly(e.date),
            'account': e.account,
          }).toList(),
      'upcoming': upcoming.take(25).map((e) => {
            'type': e.type.name,
            'title': e.title,
            'category': e.category,
            'amount': e.amount,
            'date': _dateOnly(e.date),
            'source': e.sourceName,
          }).toList(),
    };
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
          (value.toLowerCase().contains(clean) || clean.contains(value.toLowerCase()))) {
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

  String? _resolveCardId(FinanceStore store, String requestedId, String requestedName) {
    for (final card in store.data.cards) {
      if (card.id == requestedId) return card.id;
    }
    final clean = requestedName.trim().toLowerCase();
    for (final card in store.data.cards) {
      if (card.name.toLowerCase() == clean) return card.id;
    }
    for (final card in store.data.cards) {
      if (clean.isNotEmpty && card.name.toLowerCase().contains(clean)) return card.id;
    }
    return store.data.cards.length == 1 ? store.data.cards.first.id : null;
  }
}
