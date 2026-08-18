part of 'store.dart';

extension FinanceStoreTransactions on FinanceStore {
  bool _isFutureTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(date.year, date.month, date.day);
    return value.isAfter(today);
  }

  PlannedItem _plannedFromTransaction(TransactionItem item) {
    final transfer = transferAccounts(item);
    return PlannedItem(
      id: FinanceStore.newId(),
      type: item.type,
      title: item.title,
      category: item.category,
      amount: item.amount,
      date: item.date,
      sourceName: item.type == TransactionType.transfer && transfer != null
          ? transfer[0]
          : item.account,
      destinationName: item.type == TransactionType.transfer && transfer != null
          ? transfer[1]
          : null,
      paymentKind: item.paymentKind,
      cardId: item.cardId,
      recurrenceId: item.recurrenceId,
      recurrenceDate: item.recurrenceId == null ? null : item.date,
      installmentId: item.installmentId,
      installmentNumber: item.installmentNumber,
      installmentTotal: item.installmentTotal,
      invoiceMonth: item.invoiceMonth,
    );
  }

  bool _hasEquivalentPlanned(TransactionItem item) => data.planned.any((planned) {
        if (planned.status != PlannedStatus.planned) return false;
        if (item.recurrenceId != null &&
            planned.recurrenceId == item.recurrenceId) {
          return sameDay(planned.canonicalRecurrenceDate, item.date);
        }
        if (item.installmentId != null &&
            planned.installmentId == item.installmentId &&
            planned.installmentNumber == item.installmentNumber) {
          return true;
        }
        // Lançamentos manuais idênticos continuam sendo lançamentos distintos.
        return false;
      });

  void _prepareCardInvoice(TransactionItem item) {
    if (item.paymentKind == PaymentKind.card &&
        item.type == TransactionType.expense &&
        item.invoiceMonth == null) {
      final card = findCard(item.cardId);
      if (card != null) {
        item.invoiceMonth = invoiceMonthForPurchase(card, item.date);
      }
    }
  }

  bool _addTransactionInternal(TransactionItem item) {
    if (!isValidAmount(item.amount)) return false;
    _prepareCardInvoice(item);

    // Toda movimentação futura é um compromisso, inclusive transferências.
    if (_isFutureTransactionDate(item.date)) {
      if (!_hasEquivalentPlanned(item)) {
        data.planned.add(_plannedFromTransaction(item));
      }
      return true;
    }

    data.transactions.add(item);
    _applyTransactionEffect(item, reverse: false);
    return true;
  }

  void addTransaction(TransactionItem item) {
    if (_addTransactionInternal(item)) commit();
  }

  DateTime? _earliestPastMonth(DateTime a, [DateTime? b]) {
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    final first = monthStart(a);
    final second = b == null ? null : monthStart(b);
    DateTime? earliest;
    if (first.isBefore(current)) earliest = first;
    if (second != null && second.isBefore(earliest ?? second.add(const Duration(days: 1)))) {
      earliest = second;
    }
    return earliest;
  }

  void updateTransaction(TransactionItem before, TransactionItem after) {
    final index = data.transactions.indexWhere((e) => e.id == before.id);
    if (index == -1 || !isValidAmount(after.amount)) return;

    _prepareCardInvoice(after);
    if (!(after.paymentKind == PaymentKind.card &&
        after.type == TransactionType.expense)) {
      after.invoiceMonth = after.type == TransactionType.transfer
          ? after.invoiceMonth
          : null;
    }

    _applyTransactionEffect(before, reverse: true);

    if (_isFutureTransactionDate(after.date)) {
      data.transactions.removeAt(index);
      if (!_hasEquivalentPlanned(after)) {
        data.planned.add(_plannedFromTransaction(after));
      }
    } else {
      data.transactions[index] = after;
      _applyTransactionEffect(after, reverse: false);
    }

    final rebuildFrom = _earliestPastMonth(before.date, after.date);
    if (rebuildFrom != null) rebuildSnapshotsFrom(rebuildFrom);
    commit();
  }

  void deleteTransaction(TransactionItem item) {
    final exists = data.transactions.any((e) => e.id == item.id);
    if (!exists) return;

    _applyTransactionEffect(item, reverse: true);
    data.transactions.removeWhere((e) => e.id == item.id);
    final rebuildFrom = _earliestPastMonth(item.date);
    if (rebuildFrom != null) rebuildSnapshotsFrom(rebuildFrom);
    commit();
  }

  /// Migração v0.3.7.
  ///
  /// Versões anteriores aplicavam imediatamente no saldo qualquer receita ou
  /// despesa criada com data futura. Na primeira abertura, o efeito é estornado
  /// e a movimentação é migrada para Planejamento.
  Future<void> repairLegacyFutureTransactionEffects() async {
    const repairKey = 'finora_v037_future_effect_repaired';
    final prefs = await _preferences();
    if (prefs.getBool(repairKey) == true) return;

    final future = data.transactions
        .where((item) =>
            item.type != TransactionType.transfer &&
            _isFutureTransactionDate(item.date))
        .toList();

    for (final item in future) {
      _applyTransactionEffect(item, reverse: true);

      final recurrenceStillExists = item.recurrenceId == null ||
          data.recurringRules.any((rule) => rule.id == item.recurrenceId);
      final installmentStillExists = item.installmentId == null ||
          data.installmentPlans.any((plan) => plan.id == item.installmentId);

      if (recurrenceStillExists &&
          installmentStillExists &&
          !_hasEquivalentPlanned(item)) {
        data.planned.add(_plannedFromTransaction(item));
      }

      data.transactions.removeWhere((tx) => tx.id == item.id);
    }

    if (future.isNotEmpty) {
      commit();
      await flushPersistence();
    }
    await prefs.setBool(repairKey, true);
  }

  /// Migração v0.3.9.
  ///
  /// O formulário de transferência antigo aceitava uma data futura, mas o
  /// método de transferência já movia os dois saldos imediatamente. O reparo
  /// devolve esses saldos e transforma a transferência futura em previsão.
  Future<void> repairLegacyFutureTransferEffects() async {
    const repairKey = 'finora_v039_future_transfer_repaired';
    final prefs = await _preferences();
    if (prefs.getBool(repairKey) == true) return;

    final futureTransfers = data.transactions
        .where((item) =>
            item.type == TransactionType.transfer &&
            !item.title.startsWith('Pagamento fatura') &&
            _isFutureTransactionDate(item.date))
        .toList();

    for (final item in futureTransfers) {
      final accounts = transferAccounts(item);
      if (accounts != null &&
          findAccount(accounts[0]) != null &&
          findAccount(accounts[1]) != null) {
        _applyTransactionEffect(item, reverse: true);
      }

      data.planned.add(_plannedFromTransaction(item));
      data.transactions.removeWhere((tx) => tx.id == item.id);
    }

    if (futureTransfers.isNotEmpty) {
      commit();
      await flushPersistence();
    }
    await prefs.setBool(repairKey, true);
  }

  bool transfer({
    required double amount,
    required String from,
    required String to,
    DateTime? date,
  }) {
    if (!isValidAmount(amount)) return false;
    final source = findAccount(from);
    final target = findAccount(to);
    if (source == null || target == null || source == target) return false;

    final item = TransactionItem(
      id: FinanceStore.newId(),
      type: TransactionType.transfer,
      title: 'Transferência',
      category: 'Transferência',
      amount: amount,
      date: date ?? DateTime.now(),
      account: '$from → $to',
    );
    if (!_addTransactionInternal(item)) return false;
    commit();
    return true;
  }

  bool payInvoice({
    required String cardId,
    required String accountName,
    DateTime? month,
  }) {
    final card = findCard(cardId);
    final account = findAccount(accountName);
    final targetMonth = month ?? selectedMonth;
    if (card == null || account == null) return false;

    var amount = invoiceOutstandingForMonth(cardId, targetMonth);
    final now = DateTime.now();
    if (sameMonth(targetMonth, now)) {
      amount += manualCardOutstanding(cardId);
    }
    if (!isValidAmount(amount)) return false;

    final item = TransactionItem(
      id: FinanceStore.newId(),
      type: TransactionType.transfer,
      title: 'Pagamento fatura ${card.name}',
      category: 'Cartão',
      amount: amount,
      date: DateTime.now(),
      account: '$accountName → ${card.name}',
      cardId: card.id,
      invoiceMonth: DateTime(targetMonth.year, targetMonth.month),
    );
    if (!_addTransactionInternal(item)) return false;
    commit();
    return true;
  }

  List<TransactionItem> cardTransactionsForMonth(
    String cardId,
    DateTime month,
  ) =>
      cardTransactionsForInvoiceMonth(cardId, month);
}
