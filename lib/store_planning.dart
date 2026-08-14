part of 'store.dart';

extension FinanceStorePlanning on FinanceStore {
  double cashPlannedReceivableForMonth(DateTime month) => data.planned
      .where((e) =>
          e.status == PlannedStatus.planned &&
          e.type == TransactionType.income &&
          sameMonth(e.date, month))
      .fold<double>(0, (sum, item) => sum + item.amount);

  double cashPlannedPayableForMonth(DateTime month) {
    var total = 0.0;

    for (final item in data.planned) {
      if (item.status != PlannedStatus.planned ||
          item.type != TransactionType.expense) {
        continue;
      }
      if (item.paymentKind == PaymentKind.account && sameMonth(item.date, month)) {
        total += item.amount;
      } else if (item.paymentKind == PaymentKind.card) {
        final invoice = item.invoiceMonth ??
            _plannedInvoiceMonth(item.paymentKind, item.cardId, item.date);
        if (invoice != null && sameMonth(invoice, month)) {
          total += item.amount;
        }
      }
    }

    for (final card in data.cards) {
      total += invoiceOutstandingForMonth(card.id, month);
    }

    final now = DateTime.now();
    if (sameMonth(month, now)) {
      for (final card in data.cards) {
        final trackedCardPurchases = data.transactions
            .where((e) =>
                e.paymentKind == PaymentKind.card &&
                e.cardId == card.id &&
                e.type == TransactionType.expense)
            .fold<double>(0, (sum, item) => sum + item.amount);
        final paid = data.transactions
            .where((e) =>
                e.type == TransactionType.transfer &&
                e.cardId == card.id &&
                e.title.startsWith('Pagamento fatura'))
            .fold<double>(0, (sum, item) => sum + item.amount);
        final trackedOutstanding =
            (trackedCardPurchases - paid).clamp(0.0, double.infinity).toDouble();
        final manualOutstanding = (card.used - trackedOutstanding)
            .clamp(0.0, double.infinity)
            .toDouble();
        total += manualOutstanding;
      }
    }

    return total;
  }

  double cashProjectedClosingForMonth(DateTime month) {
    final target = DateTime(month.year, month.month);
    final current = DateTime(DateTime.now().year, DateTime.now().month);

    if (target.isBefore(current)) {
      final snapshot = snapshotForMonth(target);
      if (snapshot != null) return snapshot.closingBalance;
      return incomeForMonth(target) - expenseForMonth(target);
    }

    var balance = cashBalance;
    var cursor = current;
    while (!cursor.isAfter(target)) {
      balance += cashPlannedReceivableForMonth(cursor);
      balance -= cashPlannedPayableForMonth(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return balance;
  }

  double cashProjectedOpeningForMonth(DateTime month) {
    final target = DateTime(month.year, month.month);
    final current = DateTime(DateTime.now().year, DateTime.now().month);

    if (target.isBefore(current)) {
      return snapshotForMonth(target)?.openingBalance ?? 0;
    }
    if (sameMonth(target, current)) return cashBalance;
    return cashProjectedClosingForMonth(DateTime(target.year, target.month - 1));
  }

  double get selectedCashProjectedOpening =>
      cashProjectedOpeningForMonth(selectedMonth);
  double get selectedCashProjectedClosing =>
      cashProjectedClosingForMonth(selectedMonth);
  double get selectedCashPlannedPayable =>
      cashPlannedPayableForMonth(selectedMonth);
  double get selectedCashPlannedReceivable =>
      cashPlannedReceivableForMonth(selectedMonth);

  DateTime? _plannedInvoiceMonth(
    PaymentKind paymentKind,
    String? cardId,
    DateTime purchaseDate,
  ) {
    if (paymentKind != PaymentKind.card) return null;
    final card = findCard(cardId);
    if (card == null) return null;
    return invoiceMonthForPurchase(card, purchaseDate);
  }

  bool _recurrenceAllowed(
    RecurringRule rule,
    DateTime occurrence,
    int occurrenceNumber,
  ) {
    if (rule.endDate != null && occurrence.isAfter(rule.endDate!)) return false;
    if (rule.maxOccurrences != null &&
        occurrenceNumber > rule.maxOccurrences!) {
      return false;
    }
    return true;
  }

  void _materializeRecurringFuture(RecurringRule rule) {
    data.planned.removeWhere((e) =>
        e.recurrenceId == rule.id && e.status == PlannedStatus.planned);
    if (!rule.active) return;

    var cursor = rule.startDate;
    var occurrenceNumber = 1;
    final horizon = rule.maxOccurrences ?? 24;
    for (var i = 0; i < horizon - 1; i++) {
      cursor = FinanceStore.nextOccurrence(cursor, rule.frequency);
      occurrenceNumber++;
      if (!_recurrenceAllowed(rule, cursor, occurrenceNumber)) break;
      data.planned.add(PlannedItem(
        id: FinanceStore.newId(),
        type: rule.type,
        title: rule.title,
        category: rule.category,
        amount: rule.amount,
        date: cursor,
        sourceName: rule.sourceName,
        paymentKind: rule.paymentKind,
        cardId: rule.cardId,
        recurrenceId: rule.id,
        invoiceMonth:
            _plannedInvoiceMonth(rule.paymentKind, rule.cardId, cursor),
      ));
    }
  }

  void addRecurring({
    required TransactionType type,
    required String title,
    required String category,
    required double amount,
    required String sourceName,
    required PaymentKind paymentKind,
    String? cardId,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
    int? maxOccurrences,
  }) {
    final id = FinanceStore.newId();
    final rule = RecurringRule(
      id: id,
      type: type,
      title: title,
      category: category,
      amount: amount,
      sourceName: sourceName,
      paymentKind: paymentKind,
      cardId: cardId,
      startDate: startDate,
      frequency: frequency,
      endDate: endDate,
      maxOccurrences: maxOccurrences,
    );
    data.recurringRules.add(rule);

    addTransaction(TransactionItem(
      id: FinanceStore.newId(),
      type: type,
      title: title,
      category: category,
      amount: amount,
      date: startDate,
      account: sourceName,
      paymentKind: paymentKind,
      cardId: cardId,
      recurrenceId: id,
    ));
    _materializeRecurringFuture(rule);
    commit();
  }

  void updateRecurring(
    RecurringRule rule, {
    required String title,
    required String category,
    required double amount,
    required RecurrenceFrequency frequency,
    DateTime? endDate,
    int? maxOccurrences,
  }) {
    rule.title = title;
    rule.category = category;
    rule.amount = amount;
    rule.frequency = frequency;
    rule.endDate = endDate;
    rule.maxOccurrences = maxOccurrences;
    _materializeRecurringFuture(rule);
    commit();
  }

  void toggleRecurring(String id) {
    final rule = data.recurringRules.firstWhere((e) => e.id == id);
    rule.active = !rule.active;
    _materializeRecurringFuture(rule);
    commit();
  }

  void deleteRecurring(String id) {
    data.recurringRules.removeWhere((e) => e.id == id);
    for (final item in data.planned.where((e) => e.recurrenceId == id)) {
      if (item.status == PlannedStatus.planned) {
        item.status = PlannedStatus.skipped;
      }
    }
    commit();
  }

  void addInstallment({
    required String title,
    required String category,
    required double totalAmount,
    required int installments,
    required String sourceName,
    required PaymentKind paymentKind,
    String? cardId,
    required DateTime startDate,
  }) {
    final planId = FinanceStore.newId();
    final part = totalAmount / installments;
    data.installmentPlans.add(InstallmentPlan(
      id: planId,
      title: title,
      category: category,
      sourceName: sourceName,
      paymentKind: paymentKind,
      cardId: cardId,
      totalAmount: totalAmount,
      installments: installments,
      startDate: startDate,
    ));

    addTransaction(TransactionItem(
      id: FinanceStore.newId(),
      type: TransactionType.expense,
      title: '$title (1/$installments)',
      category: category,
      amount: part,
      date: startDate,
      account: sourceName,
      paymentKind: paymentKind,
      cardId: cardId,
      installmentId: planId,
      installmentNumber: 1,
      installmentTotal: installments,
    ));

    for (var i = 2; i <= installments; i++) {
      final purchaseDate = FinanceStore.addMonths(startDate, i - 1);
      data.planned.add(PlannedItem(
        id: FinanceStore.newId(),
        type: TransactionType.expense,
        title: '$title ($i/$installments)',
        category: category,
        amount: part,
        date: purchaseDate,
        sourceName: sourceName,
        paymentKind: paymentKind,
        cardId: cardId,
        installmentId: planId,
        installmentNumber: i,
        installmentTotal: installments,
        invoiceMonth:
            _plannedInvoiceMonth(paymentKind, cardId, purchaseDate),
      ));
    }
    commit();
  }

  int paidInstallments(String planId) => data.transactions
      .where((e) => e.installmentId == planId)
      .length;

  int pendingInstallments(String planId) => data.planned
      .where((e) =>
          e.installmentId == planId && e.status == PlannedStatus.planned)
      .length;

  void cancelInstallmentFuture(String planId) {
    for (final item in data.planned.where((e) => e.installmentId == planId)) {
      if (item.status == PlannedStatus.planned) {
        item.status = PlannedStatus.skipped;
      }
    }
    data.installmentPlans.removeWhere((e) => e.id == planId);
    commit();
  }

  void settlePlanned(PlannedItem item) {
    if (item.status != PlannedStatus.planned) return;
    final tx = TransactionItem(
      id: FinanceStore.newId(),
      type: item.type,
      title: item.title,
      category: item.category,
      amount: item.amount,
      date: DateTime.now(),
      account: item.sourceName,
      paymentKind: item.paymentKind,
      cardId: item.cardId,
      recurrenceId: item.recurrenceId,
      installmentId: item.installmentId,
      installmentNumber: item.installmentNumber,
      installmentTotal: item.installmentTotal,
      invoiceMonth: item.invoiceMonth,
    );
    item.status = PlannedStatus.settled;
    addTransaction(tx);
    commit();
  }

  void skipPlanned(PlannedItem item) {
    if (item.status != PlannedStatus.planned) return;
    item.status = PlannedStatus.skipped;
    commit();
  }

  void postponePlanned(PlannedItem item, DateTime newDate) {
    if (item.status != PlannedStatus.planned) return;
    item.date = newDate;
    if (item.paymentKind == PaymentKind.card) {
      item.invoiceMonth =
          _plannedInvoiceMonth(item.paymentKind, item.cardId, newDate);
    }
    commit();
  }

  void deletePlanned(String id) {
    data.planned.removeWhere((e) => e.id == id);
    commit();
  }
}
