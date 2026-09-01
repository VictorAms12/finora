import '../models.dart';
import '../store.dart';

enum CopilotActionType {
  createBudget,
  createGoal,
  createReserve,
  createPlanned,
}

class CopilotMemoryCandidate {
  final String label;
  final String value;

  const CopilotMemoryCandidate({required this.label, required this.value});
}

class CopilotQueryResult {
  final String message;
  final List<String> followUps;

  const CopilotQueryResult(this.message, {this.followUps = const []});
}

class CopilotActionProposal {
  final CopilotActionType type;
  final String title;
  final String summary;
  final double amount;
  final String? category;
  final DateTime? date;
  final TransactionType transactionType;
  final PaymentKind paymentKind;
  final String? sourceName;
  final String? cardId;
  final int? months;
  final DateTime? deadline;

  const CopilotActionProposal({
    required this.type,
    required this.title,
    required this.summary,
    required this.amount,
    this.category,
    this.date,
    this.transactionType = TransactionType.expense,
    this.paymentKind = PaymentKind.account,
    this.sourceName,
    this.cardId,
    this.months,
    this.deadline,
  });

  bool apply(FinanceStore store) {
    if (!amount.isFinite || amount <= 0) return false;

    switch (type) {
      case CopilotActionType.createBudget:
        final targetCategory = category?.trim();
        if (targetCategory == null ||
            targetCategory.isEmpty ||
            !store.expenseCategories.contains(targetCategory)) {
          return false;
        }
        return store.addBudget(targetCategory, amount);

      case CopilotActionType.createGoal:
        final clean = title.trim();
        if (clean.isEmpty) return false;
        return store.addGoal(
          clean,
          amount,
          0,
          deadline ?? DateTime.now().add(const Duration(days: 180)),
        );

      case CopilotActionType.createReserve:
        final clean = title.trim();
        if (clean.isEmpty) return false;
        return store.addReserve(
          clean,
          amount,
          0,
          months: (months ?? 6).clamp(1, 60).toInt(),
        );

      case CopilotActionType.createPlanned:
        final clean = title.trim();
        final due = date;
        final source = sourceName?.trim();
        if (clean.isEmpty || due == null || source == null || source.isEmpty) {
          return false;
        }
        if (transactionType == TransactionType.transfer) return false;
        if (transactionType == TransactionType.income &&
            paymentKind == PaymentKind.card) {
          return false;
        }

        String resolvedSource = source;
        String? resolvedCardId;
        DateTime? invoiceMonth;
        if (paymentKind == PaymentKind.card) {
          final card = store.findCard(cardId);
          if (card == null || transactionType != TransactionType.expense) {
            return false;
          }
          resolvedSource = card.name;
          resolvedCardId = card.id;
          invoiceMonth = store.invoiceMonthForPurchase(card, due);
        } else if (store.findAccount(source) == null) {
          return false;
        }

        final allowedCategories = transactionType == TransactionType.income
            ? store.incomeCategories
            : store.expenseCategories;
        final resolvedCategory =
            category != null && allowedCategories.contains(category)
            ? category!
            : allowedCategories.last;

        store.data.planned.add(
          PlannedItem(
            id: FinanceStore.newId(),
            type: transactionType,
            title: clean,
            category: resolvedCategory,
            amount: amount,
            date: DateTime(due.year, due.month, due.day),
            sourceName: resolvedSource,
            paymentKind: paymentKind,
            cardId: resolvedCardId,
            invoiceMonth: invoiceMonth,
          ),
        );
        store.commit();
        return true;
    }
  }
}

class FinancialQueryEngine {
  const FinancialQueryEngine();

  CopilotQueryResult? answer(FinanceStore store, String question) {
    final clean = _fold(question);
    if (clean.isEmpty) return null;

    final simulation = _simulatePurchase(store, clean, question);
    if (simulation != null) return simulation;

    if (_hasAny(clean, [
      'pior mes',
      'mes que mais gastei',
      'qual mes gastei mais',
      'maior gasto mensal',
    ])) {
      return _worstMonth(store);
    }

    if (_hasAny(clean, [
      'media por dia',
      'média por dia',
      'gasto medio diario',
      'gasto médio diário',
      'quanto gasto por dia',
    ])) {
      return _dailyAverage(store);
    }

    if (_hasAny(clean, [
      'maior categoria',
      'categoria que mais gasto',
      'onde gasto mais',
      'onde estou gastando mais',
    ])) {
      return _topCategory(store);
    }

    if (_hasAny(clean, ['assinaturas', 'recorrencias', 'recorrências'])) {
      return _recurringSummary(store);
    }

    final categoryHistory = _categoryHistory(store, clean);
    if (categoryHistory != null) return categoryHistory;

    final projection = _projectionMonths(store, clean);
    if (projection != null) return projection;

    return null;
  }

  CopilotQueryResult? _simulatePurchase(
    FinanceStore store,
    String clean,
    String original,
  ) {
    if (!_hasAny(clean, [
      'posso comprar',
      'da pra comprar',
      'dá pra comprar',
      'simula',
      'simular',
      'cabe no orcamento',
      'cabe no orçamento',
      'e em ',
    ])) {
      return null;
    }

    final amount = _moneyFromText(original);
    if (amount == null || amount <= 0) return null;
    final installments = _installmentsFromText(clean) ?? 1;

    if (installments <= 1) {
      final before = store.availableToSpend;
      final after = before - amount;
      final status = after >= 0
          ? 'cabe dentro do disponível atual'
          : 'ultrapassa o disponível atual em ${_money(-after)}';
      return CopilotQueryResult(
        'À vista, uma compra de ${_money(amount)} $status. '
        'Seu disponível passaria de ${_money(before)} para ${_money(after)}.',
        followUps: const [
          'E parcelado?',
          'Quais contas ainda vencem este mês?',
        ],
      );
    }

    final monthly = amount / installments;
    var minimum = double.infinity;
    var minimumMonth = DateTime.now();
    for (var i = 0; i < installments; i++) {
      final month = DateTime(DateTime.now().year, DateTime.now().month + i);
      final projected =
          store.cashProjectedClosingForMonth(month) - monthly * (i + 1);
      if (projected < minimum) {
        minimum = projected;
        minimumMonth = month;
      }
    }
    final risk = minimum < 0
        ? 'A projeção ficaria negativa em ${_monthName(minimumMonth)} (${_money(minimum)}).'
        : 'A menor projeção de caixa continuaria positiva, em ${_money(minimum)}.';
    return CopilotQueryResult(
      'Em ${installments}x, a parcela seria de ${_money(monthly)}. $risk '
      'A simulação usa seus compromissos já planejados e não inclui juros que não estejam cadastrados.',
      followUps: const ['Comparar com à vista', 'Ver próximos compromissos'],
    );
  }

  CopilotQueryResult _worstMonth(FinanceStore store) {
    final now = DateTime.now();
    DateTime? worst;
    var value = -1.0;
    for (var i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i);
      final expense = store.expenseForMonth(month);
      if (expense > value) {
        value = expense;
        worst = month;
      }
    }
    if (worst == null || value <= 0) {
      return const CopilotQueryResult(
        'Ainda não há despesas suficientes para identificar seu mês de maior gasto.',
      );
    }
    return CopilotQueryResult(
      'Nos últimos 12 meses, ${_monthName(worst)} foi o período em que você mais gastou: ${_money(value)}.',
      followUps: const ['O que mais pesou nesse mês?', 'Comparar com este mês'],
    );
  }

  CopilotQueryResult _dailyAverage(FinanceStore store) {
    final month = store.selectedMonth;
    final now = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final days = store.sameMonth(month, now) ? now.day : daysInMonth;
    final expense = store.expenseForMonth(month);
    final average = days <= 0 ? 0.0 : expense / days;
    return CopilotQueryResult(
      'Em ${_monthName(month)}, sua média de despesas está em ${_money(average)} por dia '
      '(${_money(expense)} em $days dia(s) considerados).',
      followUps: const [
        'Onde estou gastando mais?',
        'Comparar com o mês passado',
      ],
    );
  }

  CopilotQueryResult _topCategory(FinanceStore store) {
    final entries = <String, double>{};
    for (final tx in store.transactionsForMonth(store.selectedMonth)) {
      if (tx.type != TransactionType.expense) continue;
      entries[tx.category] = (entries[tx.category] ?? 0) + tx.amount;
    }
    if (entries.isEmpty) {
      return const CopilotQueryResult(
        'Ainda não há despesas neste período para comparar categorias.',
      );
    }
    final sorted = entries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final total = entries.values.fold<double>(0, (sum, value) => sum + value);
    final share = total <= 0 ? 0 : (top.value / total * 100).round();
    return CopilotQueryResult(
      '${top.key} é sua maior categoria em ${_monthName(store.selectedMonth)}: '
      '${_money(top.value)}, cerca de $share% das despesas do período.',
      followUps: const [
        'Comparar com meses anteriores',
        'Ver movimentações dessa categoria',
      ],
    );
  }

  CopilotQueryResult _recurringSummary(FinanceStore store) {
    final active = store.data.recurringRules
        .where((rule) => rule.active)
        .toList();
    if (active.isEmpty) {
      return const CopilotQueryResult(
        'Você não tem recorrências ativas no momento.',
      );
    }
    var monthlyEquivalent = 0.0;
    for (final rule in active.where(
      (rule) => rule.type == TransactionType.expense,
    )) {
      switch (rule.frequency) {
        case RecurrenceFrequency.weekly:
          monthlyEquivalent += rule.amount * 52 / 12;
          break;
        case RecurrenceFrequency.monthly:
          monthlyEquivalent += rule.amount;
          break;
        case RecurrenceFrequency.yearly:
          monthlyEquivalent += rule.amount / 12;
          break;
      }
    }
    return CopilotQueryResult(
      'Você tem ${active.length} recorrência(s) ativa(s). As despesas recorrentes representam aproximadamente '
      '${_money(monthlyEquivalent)} por mês.',
      followUps: const ['Quais são as próximas?', 'Abrir planejamento'],
    );
  }

  CopilotQueryResult? _categoryHistory(FinanceStore store, String clean) {
    final monthsMatch = RegExp(r'ultimos?\s+(\d{1,2})\s+mes').firstMatch(clean);
    final asksHistory =
        monthsMatch != null ||
        _hasAny(clean, [
          'nos ultimos meses',
          'historico',
          'histórico',
          'quanto gastei com',
        ]);
    if (!asksHistory) return null;

    String? category;
    for (final candidate in store.expenseCategories) {
      if (clean.contains(_fold(candidate))) {
        category = candidate;
        break;
      }
    }
    if (category == null) return null;

    final months = (int.tryParse(monthsMatch?.group(1) ?? '') ?? 6)
        .clamp(1, 24)
        .toInt();
    final now = DateTime.now();
    var total = 0.0;
    for (var i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month - i);
      total += store
          .transactionsForMonth(month)
          .where(
            (tx) =>
                tx.type == TransactionType.expense && tx.category == category,
          )
          .fold<double>(0, (sum, tx) => sum + tx.amount);
    }
    return CopilotQueryResult(
      'Nos últimos $months meses, você gastou ${_money(total)} em $category, '
      'uma média de ${_money(total / months)} por mês.',
      followUps: const [
        'Qual mês foi o mais alto?',
        'Comparar com outra categoria',
      ],
    );
  }

  CopilotQueryResult? _projectionMonths(FinanceStore store, String clean) {
    if (!_hasAny(clean, [
      'quanto vou ter',
      'projecao daqui',
      'projeção daqui',
    ])) {
      return null;
    }
    final match = RegExp(r'(\d{1,2})\s+mes').firstMatch(clean);
    if (match == null) return null;
    final months = (int.tryParse(match.group(1) ?? '') ?? 1)
        .clamp(1, 24)
        .toInt();
    final target = DateTime(DateTime.now().year, DateTime.now().month + months);
    final projected = store.cashProjectedClosingForMonth(target);
    return CopilotQueryResult(
      'Mantendo o que já está planejado, o saldo projetado para ${_monthName(target)} é ${_money(projected)}.',
      followUps: const [
        'O que está incluído nessa projeção?',
        'Ver planejamento',
      ],
    );
  }

  bool _hasAny(String source, List<String> values) =>
      values.any((value) => source.contains(_fold(value)));

  int? _installmentsFromText(String text) {
    final x = RegExp(r'\b(\d{1,2})\s*x\b').firstMatch(text);
    final words = RegExp(
      r'\bem\s+(\d{1,2})\s+(?:vezes|parcelas)\b',
    ).firstMatch(text);
    final raw = x?.group(1) ?? words?.group(1);
    final value = int.tryParse(raw ?? '');
    if (value == null || value < 2 || value > 60) return null;
    return value;
  }

  double? _moneyFromText(String text) {
    final explicit = RegExp(
      r'r\$\s*([0-9][0-9.,]*)',
      caseSensitive: false,
    ).firstMatch(text);
    final candidates = <double>[];
    if (explicit != null) {
      final value = _parseNumber(explicit.group(1)!);
      if (value != null) return value;
    }
    for (final match in RegExp(r'\b\d+(?:[\.,]\d{1,2})?\b').allMatches(text)) {
      final value = _parseNumber(match.group(0)!);
      if (value != null && value > 0) candidates.add(value);
    }
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.last;
  }

  double? _parseNumber(String value) {
    var clean = value.trim();
    if (clean.contains(',') && clean.contains('.')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    } else if (clean.contains(',')) {
      clean = clean.replaceAll(',', '.');
    }
    return double.tryParse(clean);
  }

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

  String _monthName(DateTime value) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${months[value.month - 1]} de ${value.year}';
  }
}
