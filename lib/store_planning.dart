part of 'store.dart';

extension FinanceStorePlanning on FinanceStore {
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
  }) {
    final id = FinanceStore.newId();
    data.recurringRules.add(RecurringRule(
      id: id, type: type, title: title, category: category, amount: amount,
      sourceName: sourceName, paymentKind: paymentKind, cardId: cardId,
      startDate: startDate, frequency: frequency,
    ));
    addTransaction(TransactionItem(
      id: FinanceStore.newId(), type: type, title: title, category: category,
      amount: amount, date: startDate, account: sourceName,
      paymentKind: paymentKind, cardId: cardId, recurrenceId: id,
    ));
    var cursor = startDate;
    for (var i = 0; i < 12; i++) {
      cursor = FinanceStore.nextOccurrence(cursor, frequency);
      data.planned.add(PlannedItem(
        id: FinanceStore.newId(), type: type, title: title, category: category,
        amount: amount, date: cursor, sourceName: sourceName,
        paymentKind: paymentKind, cardId: cardId, recurrenceId: id,
      ));
    }
    commit();
  }

  void toggleRecurring(String id) {
    final rule = data.recurringRules.firstWhere((e) => e.id == id);
    rule.active = !rule.active;
    if (!rule.active) {
      data.planned.removeWhere((e) => e.recurrenceId == id);
    } else {
      var cursor = DateTime.now().isAfter(rule.startDate)
          ? DateTime.now()
          : rule.startDate;
      for (var i = 0; i < 12; i++) {
        cursor = FinanceStore.nextOccurrence(cursor, rule.frequency);
        data.planned.add(PlannedItem(
          id: FinanceStore.newId(), type: rule.type, title: rule.title,
          category: rule.category, amount: rule.amount, date: cursor,
          sourceName: rule.sourceName, paymentKind: rule.paymentKind,
          cardId: rule.cardId, recurrenceId: rule.id,
        ));
      }
    }
    commit();
  }

  void deleteRecurring(String id) {
    data.recurringRules.removeWhere((e) => e.id == id);
    data.planned.removeWhere((e) => e.recurrenceId == id);
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
      id: planId, title: title, category: category, sourceName: sourceName,
      paymentKind: paymentKind, cardId: cardId, totalAmount: totalAmount,
      installments: installments, startDate: startDate,
    ));
    addTransaction(TransactionItem(
      id: FinanceStore.newId(), type: TransactionType.expense,
      title: '$title (1/$installments)', category: category, amount: part,
      date: startDate, account: sourceName, paymentKind: paymentKind,
      cardId: cardId, installmentId: planId, installmentNumber: 1,
      installmentTotal: installments,
    ));
    for (var i = 2; i <= installments; i++) {
      data.planned.add(PlannedItem(
        id: FinanceStore.newId(), type: TransactionType.expense,
        title: '$title ($i/$installments)', category: category, amount: part,
        date: FinanceStore.addMonths(startDate, i - 1), sourceName: sourceName,
        paymentKind: paymentKind, cardId: cardId, installmentId: planId,
        installmentNumber: i, installmentTotal: installments,
      ));
    }
    commit();
  }

  int paidInstallments(String planId) =>
      data.transactions.where((e) => e.installmentId == planId).length;
  int pendingInstallments(String planId) =>
      data.planned.where((e) => e.installmentId == planId).length;

  void cancelInstallmentFuture(String planId) {
    data.planned.removeWhere((e) => e.installmentId == planId);
    data.installmentPlans.removeWhere((e) => e.id == planId);
    commit();
  }

  void settlePlanned(PlannedItem item) {
    final tx = TransactionItem(
      id: FinanceStore.newId(), type: item.type, title: item.title,
      category: item.category, amount: item.amount, date: DateTime.now(),
      account: item.sourceName, paymentKind: item.paymentKind, cardId: item.cardId,
      recurrenceId: item.recurrenceId, installmentId: item.installmentId,
      installmentNumber: item.installmentNumber, installmentTotal: item.installmentTotal,
    );
    data.planned.removeWhere((e) => e.id == item.id);
    data.transactions.add(tx);
    _applyTransactionEffect(tx, reverse: false);
    commit();
  }

  void deletePlanned(String id) {
    data.planned.removeWhere((e) => e.id == id);
    commit();
  }
}
