part of 'store.dart';

extension FinanceStorePlanning on FinanceStore {
  void repairTrackingBaseline() {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    if (data.snapshots.isEmpty &&
        data.trackingMonth != null &&
        sameMonth(data.trackingMonth!, now)) {
      final expected = cashBalance - cashMovementForMonth(now);
      if ((data.trackingOpeningCash - expected).abs() > 0.005) {
        data.trackingOpeningCash = expected;
        commit();
      }
    }
  }

  bool _plannedDueInMonth(DateTime dueDate, DateTime month) {
    final target = monthStart(month);
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    final due = monthStart(dueDate);
    if (sameMonth(target, current)) return !due.isAfter(current);
    return sameMonth(due, target);
  }

  double cashPlannedReceivableForMonth(DateTime month) => data.planned
      .where(
        (e) =>
            e.status == PlannedStatus.planned &&
            e.type == TransactionType.income &&
            e.paymentKind == PaymentKind.account &&
            _plannedDueInMonth(e.date, month),
      )
      .fold<double>(0, (sum, item) => sum + item.amount);

  double cashPlannedPayableForMonth(DateTime month) {
    var total = 0.0;

    for (final item in data.planned) {
      if (item.status != PlannedStatus.planned ||
          item.type != TransactionType.expense) {
        continue;
      }
      if (item.paymentKind == PaymentKind.account &&
          _plannedDueInMonth(item.date, month)) {
        total += item.amount;
      } else if (item.paymentKind == PaymentKind.card) {
        final invoice =
            item.invoiceMonth ??
            _plannedInvoiceMonth(item.paymentKind, item.cardId, item.date);
        if (invoice != null && _plannedDueInMonth(invoice, month)) {
          total += item.amount;
        }
      }
    }

    for (final card in data.cards) {
      total += cardOutstandingDueForPlanningMonth(card.id, month);
    }

    return total;
  }

  double get currentAvailableToSpend => availableToSpend;

  double get currentAvailablePerDay {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (lastDay - now.day + 1).clamp(1, 31);
    return currentAvailableToSpend / remainingDays;
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
    return cashProjectedClosingForMonth(
      DateTime(target.year, target.month - 1),
    );
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

  bool isFifthBusinessDaySalaryRule(RecurringRule rule) =>
      rule.id.startsWith('salary5-') &&
      rule.frequency == RecurrenceFrequency.monthly;

  DateTime fifthBusinessDayOfMonth(DateTime month) {
    var businessDays = 0;
    var day = 1;
    while (true) {
      final date = DateTime(month.year, month.month, day);
      final weekday = date.weekday;
      if (weekday != DateTime.saturday && weekday != DateTime.sunday) {
        businessDays++;
        if (businessDays == 5) return date;
      }
      day++;
    }
  }

  DateTime _nextOccurrenceForRule(RecurringRule rule, DateTime current) {
    if (isFifthBusinessDaySalaryRule(rule)) {
      return fifthBusinessDayOfMonth(DateTime(current.year, current.month + 1));
    }
    return FinanceStore.nextOccurrence(current, rule.frequency);
  }

  int _futureRecurrenceHorizon(RecurringRule rule) {
    switch (rule.frequency) {
      case RecurrenceFrequency.weekly:
        return 52;
      case RecurrenceFrequency.monthly:
        return 24;
      case RecurrenceFrequency.yearly:
        return 10;
    }
  }

  String _occurrenceKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  bool _transactionRepresentsOccurrence(
    RecurringRule rule,
    DateTime occurrence,
  ) => data.transactions.any(
    (tx) =>
        tx.recurrenceId == rule.id &&
        sameDay(tx.recurrenceDate ?? tx.date, occurrence),
  );

  void _updateRecurringPlannedItem(
    PlannedItem item,
    RecurringRule rule,
    DateTime canonicalDate,
  ) {
    item.type = rule.type;
    item.title = rule.title;
    item.category = rule.category;
    item.amount = rule.amount;
    item.sourceName = rule.sourceName;
    item.paymentKind = rule.paymentKind;
    item.cardId = rule.cardId;
    item.recurrenceDate = canonicalDate;
    item.invoiceMonth = _plannedInvoiceMonth(
      rule.paymentKind,
      rule.cardId,
      item.date,
    );
  }

  void _materializeRecurringFuture(RecurringRule rule) {
    final existing = data.planned
        .where((item) => item.recurrenceId == rule.id)
        .toList();

    if (!rule.active) {
      data.planned.removeWhere(
        (item) =>
            item.recurrenceId == rule.id &&
            item.status == PlannedStatus.planned,
      );
      return;
    }

    final byOccurrence = <String, PlannedItem>{};
    for (final item in existing) {
      byOccurrence.putIfAbsent(
        _occurrenceKey(item.canonicalRecurrenceDate),
        () => item,
      );
    }

    final retainedPendingIds = <String>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final catchUpStart = FinanceStore.addMonths(today, -12);
    final futureLimit = _futureRecurrenceHorizon(rule);

    var cursor = DateTime(
      rule.startDate.year,
      rule.startDate.month,
      rule.startDate.day,
    );
    var occurrenceNumber = 1;
    var futureOccurrences = 0;
    var safety = 0;

    while (safety < 5000 &&
        _recurrenceAllowed(rule, cursor, occurrenceNumber)) {
      final canonical = DateTime(cursor.year, cursor.month, cursor.day);
      final key = _occurrenceKey(canonical);
      final item = byOccurrence[key];
      final future = canonical.isAfter(today);
      final representedByTransaction = _transactionRepresentsOccurrence(
        rule,
        canonical,
      );

      if (item != null) {
        if (item.status == PlannedStatus.planned) {
          _updateRecurringPlannedItem(item, rule, canonical);
          retainedPendingIds.add(item.id);
        }
      } else if (!representedByTransaction &&
          (future || !canonical.isBefore(catchUpStart))) {
        final planned = PlannedItem(
          id: FinanceStore.newId(),
          type: rule.type,
          title: rule.title,
          category: rule.category,
          amount: rule.amount,
          date: canonical,
          sourceName: rule.sourceName,
          paymentKind: rule.paymentKind,
          cardId: rule.cardId,
          recurrenceId: rule.id,
          recurrenceDate: canonical,
          invoiceMonth: _plannedInvoiceMonth(
            rule.paymentKind,
            rule.cardId,
            canonical,
          ),
        );
        data.planned.add(planned);
        retainedPendingIds.add(planned.id);
      }

      if (future) {
        futureOccurrences++;
        if (rule.maxOccurrences == null &&
            rule.endDate == null &&
            futureOccurrences >= futureLimit) {
          break;
        }
      }

      cursor = _nextOccurrenceForRule(rule, cursor);
      occurrenceNumber++;
      safety++;
    }

    data.planned.removeWhere(
      (item) =>
          item.recurrenceId == rule.id &&
          item.status == PlannedStatus.planned &&
          !retainedPendingIds.contains(item.id),
    );
  }

  void refreshRecurringPlanning({bool persist = true}) {
    for (final rule in data.recurringRules) {
      _materializeRecurringFuture(rule);
    }
    if (persist) commit();
  }

  bool _validRecurringSource(
    TransactionType type,
    PaymentKind paymentKind,
    String sourceName,
    String? cardId,
  ) {
    if (type == TransactionType.income && paymentKind == PaymentKind.card) {
      return false;
    }
    if (paymentKind == PaymentKind.card) return findCard(cardId) != null;
    return findAccount(sourceName) != null;
  }

  bool addRecurring({
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
    num? maxOccurrences,
  }) {
    if (!isValidAmount(amount) ||
        title.trim().isEmpty ||
        !_validRecurringSource(type, paymentKind, sourceName, cardId)) {
      return false;
    }
    if (endDate != null && endDate.isBefore(startDate)) return false;
    final max = maxOccurrences?.toInt();
    if (max != null && max < 1) return false;

    final id = FinanceStore.newId();
    final rule = RecurringRule(
      id: id,
      type: type,
      title: title.trim(),
      category: category,
      amount: amount,
      sourceName: sourceName,
      paymentKind: paymentKind,
      cardId: cardId,
      startDate: startDate,
      frequency: frequency,
      endDate: endDate,
      maxOccurrences: max,
    );
    data.recurringRules.add(rule);

    if (!_isFutureTransactionDate(startDate)) {
      _addTransactionInternal(
        TransactionItem(
          id: FinanceStore.newId(),
          type: type,
          title: rule.title,
          category: category,
          amount: amount,
          date: startDate,
          account: sourceName,
          paymentKind: paymentKind,
          cardId: cardId,
          recurrenceId: id,
          recurrenceDate: startDate,
        ),
      );
    }

    _materializeRecurringFuture(rule);
    commit();
    return true;
  }

  bool addSalaryOnFifthBusinessDay({
    required double amount,
    required String sourceName,
    DateTime? startMonth,
    String title = 'Salário',
    String category = 'Renda',
    DateTime? endDate,
    num? maxOccurrences,
  }) {
    if (!isValidAmount(amount) ||
        title.trim().isEmpty ||
        findAccount(sourceName) == null) {
      return false;
    }

    final now = DateTime.now();
    var month = startMonth ?? DateTime(now.year, now.month + 1);
    var firstDate = fifthBusinessDayOfMonth(month);
    final today = DateTime(now.year, now.month, now.day);

    if (firstDate.isBefore(today)) {
      month = DateTime(month.year, month.month + 1);
      firstDate = fifthBusinessDayOfMonth(month);
    }
    if (endDate != null && endDate.isBefore(firstDate)) return false;
    final max = maxOccurrences?.toInt();
    if (max != null && max < 1) return false;

    final id = 'salary5-${FinanceStore.newId()}';
    final rule = RecurringRule(
      id: id,
      type: TransactionType.income,
      title: title.trim(),
      category: category,
      amount: amount,
      sourceName: sourceName,
      paymentKind: PaymentKind.account,
      startDate: firstDate,
      frequency: RecurrenceFrequency.monthly,
      endDate: endDate,
      maxOccurrences: max,
    );

    data.recurringRules.add(rule);
    if (!_isFutureTransactionDate(firstDate)) {
      _addTransactionInternal(
        TransactionItem(
          id: FinanceStore.newId(),
          type: TransactionType.income,
          title: rule.title,
          category: category,
          amount: amount,
          date: firstDate,
          account: sourceName,
          paymentKind: PaymentKind.account,
          recurrenceId: id,
          recurrenceDate: firstDate,
        ),
      );
    }
    _materializeRecurringFuture(rule);
    commit();
    return true;
  }

  bool updateRecurring(
    RecurringRule rule, {
    required String title,
    required String category,
    required double amount,
    required RecurrenceFrequency frequency,
    DateTime? endDate,
    num? maxOccurrences,
  }) {
    if (!isValidAmount(amount) || title.trim().isEmpty) return false;
    if (endDate != null && endDate.isBefore(rule.startDate)) return false;
    final max = maxOccurrences?.toInt();
    if (max != null && max < 1) return false;

    rule.title = title.trim();
    rule.category = category;
    rule.amount = amount;
    rule.frequency = frequency;
    rule.endDate = endDate;
    rule.maxOccurrences = max;
    _materializeRecurringFuture(rule);
    commit();
    return true;
  }

  void toggleRecurring(String id) {
    final index = data.recurringRules.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final rule = data.recurringRules[index];
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

  bool addInstallment({
    required String title,
    required String category,
    required double totalAmount,
    required int installments,
    required String sourceName,
    required PaymentKind paymentKind,
    String? cardId,
    required DateTime startDate,
  }) {
    if (!isValidAmount(totalAmount) ||
        installments < 2 ||
        title.trim().isEmpty) {
      return false;
    }
    if (paymentKind == PaymentKind.card) {
      if (findCard(cardId) == null) return false;
    } else if (findAccount(sourceName) == null) {
      return false;
    }

    final planId = FinanceStore.newId();
    final part = totalAmount / installments;
    data.installmentPlans.add(
      InstallmentPlan(
        id: planId,
        title: title.trim(),
        category: category,
        sourceName: sourceName,
        paymentKind: paymentKind,
        cardId: cardId,
        totalAmount: totalAmount,
        installments: installments,
        startDate: startDate,
      ),
    );

    _addTransactionInternal(
      TransactionItem(
        id: FinanceStore.newId(),
        type: TransactionType.expense,
        title: '${title.trim()} (1/$installments)',
        category: category,
        amount: part,
        date: startDate,
        account: sourceName,
        paymentKind: paymentKind,
        cardId: cardId,
        installmentId: planId,
        installmentNumber: 1,
        installmentTotal: installments,
      ),
    );

    for (var i = 2; i <= installments; i++) {
      final purchaseDate = FinanceStore.addMonths(startDate, i - 1);
      data.planned.add(
        PlannedItem(
          id: FinanceStore.newId(),
          type: TransactionType.expense,
          title: '${title.trim()} ($i/$installments)',
          category: category,
          amount: part,
          date: purchaseDate,
          sourceName: sourceName,
          paymentKind: paymentKind,
          cardId: cardId,
          installmentId: planId,
          installmentNumber: i,
          installmentTotal: installments,
          invoiceMonth: _plannedInvoiceMonth(paymentKind, cardId, purchaseDate),
        ),
      );
    }
    commit();
    return true;
  }

  int paidInstallments(String planId) =>
      data.transactions.where((e) => e.installmentId == planId).length;

  int pendingInstallments(String planId) => data.planned
      .where(
        (e) => e.installmentId == planId && e.status == PlannedStatus.planned,
      )
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

  bool _canSettlePlanned(PlannedItem item) {
    if (item.type == TransactionType.transfer) {
      return findAccount(item.sourceName) != null &&
          item.destinationName != null &&
          findAccount(item.destinationName!) != null &&
          item.sourceName != item.destinationName;
    }
    if (item.type == TransactionType.income &&
        item.paymentKind == PaymentKind.card) {
      return false;
    }
    if (item.paymentKind == PaymentKind.card) {
      return findCard(item.cardId) != null;
    }
    return findAccount(item.sourceName) != null;
  }

  bool settlePlanned(PlannedItem item) {
    if (item.status != PlannedStatus.planned || !_canSettlePlanned(item)) {
      return false;
    }

    final account = item.type == TransactionType.transfer
        ? '${item.sourceName} → ${item.destinationName}'
        : item.sourceName;
    final tx = TransactionItem(
      id: FinanceStore.newId(),
      type: item.type,
      title: item.title,
      category: item.category,
      amount: item.amount,
      date: DateTime.now(),
      account: account,
      paymentKind: item.paymentKind,
      cardId: item.cardId,
      recurrenceId: item.recurrenceId,
      recurrenceDate: item.recurrenceId == null
          ? null
          : item.canonicalRecurrenceDate,
      installmentId: item.installmentId,
      installmentNumber: item.installmentNumber,
      installmentTotal: item.installmentTotal,
      invoiceMonth: item.invoiceMonth,
    );
    if (!_addTransactionInternal(tx)) return false;
    item.status = PlannedStatus.settled;
    commit();
    return true;
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
      item.invoiceMonth = _plannedInvoiceMonth(
        item.paymentKind,
        item.cardId,
        newDate,
      );
    }
    commit();
  }

  void deletePlanned(String id) {
    final index = data.planned.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final item = data.planned[index];
    if (item.recurrenceId != null || item.installmentId != null) {
      item.status = PlannedStatus.skipped;
    } else {
      data.planned.removeAt(index);
    }
    commit();
  }
}
