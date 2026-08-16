part of 'store.dart';

extension FinanceStoreTransactions on FinanceStore {
  bool _isFutureTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(date.year, date.month, date.day);
    return value.isAfter(today);
  }

  PlannedItem _plannedFromTransaction(TransactionItem item) => PlannedItem(
        id: FinanceStore.newId(),
        type: item.type,
        title: item.title,
        category: item.category,
        amount: item.amount,
        date: item.date,
        sourceName: item.account,
        paymentKind: item.paymentKind,
        cardId: item.cardId,
        recurrenceId: item.recurrenceId,
        installmentId: item.installmentId,
        installmentNumber: item.installmentNumber,
        installmentTotal: item.installmentTotal,
        invoiceMonth: item.invoiceMonth,
      );

  bool _hasEquivalentPlanned(TransactionItem item) => data.planned.any((planned) {
        if (planned.status != PlannedStatus.planned) return false;
        if (item.recurrenceId != null && planned.recurrenceId == item.recurrenceId) {
          return planned.date.year == item.date.year &&
              planned.date.month == item.date.month &&
              planned.date.day == item.date.day;
        }
        if (item.installmentId != null &&
            planned.installmentId == item.installmentId &&
            planned.installmentNumber == item.installmentNumber) {
          return true;
        }
        return planned.title == item.title &&
            planned.amount == item.amount &&
            planned.date.year == item.date.year &&
            planned.date.month == item.date.month &&
            planned.date.day == item.date.day &&
            planned.sourceName == item.account;
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

  void addTransaction(TransactionItem item) {
    _prepareCardInvoice(item);

    // Uma movimentação com data futura ainda não aconteceu. Ela entra no
    // planejamento e só afeta conta/cartão quando for efetivamente realizada.
    if (item.type != TransactionType.transfer &&
        _isFutureTransactionDate(item.date)) {
      if (!_hasEquivalentPlanned(item)) {
        data.planned.add(_plannedFromTransaction(item));
      }
      commit();
      return;
    }

    data.transactions.add(item);
    _applyTransactionEffect(item, reverse: false);
    commit();
  }

  void updateTransaction(TransactionItem before, TransactionItem after) {
    final index = data.transactions.indexWhere((e) => e.id == before.id);
    if (index == -1) return;

    _prepareCardInvoice(after);
    if (!(after.paymentKind == PaymentKind.card &&
        after.type == TransactionType.expense)) {
      after.invoiceMonth = null;
    }

    final beforeWasFuture = _isFutureTransactionDate(before.date);
    if (!beforeWasFuture) {
      _applyTransactionEffect(before, reverse: true);
    }

    if (after.type != TransactionType.transfer &&
        _isFutureTransactionDate(after.date)) {
      data.transactions.removeAt(index);
      if (!_hasEquivalentPlanned(after)) {
        data.planned.add(_plannedFromTransaction(after));
      }
      commit();
      return;
    }

    data.transactions[index] = after;
    _applyTransactionEffect(after, reverse: false);
    commit();
  }

  void deleteTransaction(TransactionItem item) {
    if (!_isFutureTransactionDate(item.date)) {
      _applyTransactionEffect(item, reverse: true);
    }
    data.transactions.removeWhere((e) => e.id == item.id);
    commit();
  }

  /// Migração v0.3.7.
  ///
  /// Versões anteriores aplicavam imediatamente no saldo qualquer transação
  /// criada com data futura. Na primeira abertura desta versão, o efeito é
  /// estornado e a movimentação é migrada para Planejamento.
  ///
  /// Se a movimentação pertencia a uma recorrência/parcelamento já excluído,
  /// ela é removida em vez de recriada como previsão.
  Future<void> repairLegacyFutureTransactionEffects() async {
    const repairKey = 'finora_v037_future_effect_repaired';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(repairKey) == true) return;

    final future = data.transactions
        .where((item) =>
            item.type != TransactionType.transfer &&
            _isFutureTransactionDate(item.date))
        .toList();

    for (final item in future) {
      // O saldo/cartão já havia sido alterado pela versão antiga.
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

    await _save();
    await prefs.setBool(repairKey, true);
    // commit() pertence ao FinanceStore e faz a notificação de forma válida.
    commit();
  }

  void transfer({
    required double amount,
    required String from,
    required String to,
    DateTime? date,
  }) {
    final source = findAccount(from);
    final target = findAccount(to);
    if (source == null || target == null || source == target) return;
    source.balance -= amount;
    target.balance += amount;
    data.transactions.add(TransactionItem(
      id: FinanceStore.newId(),
      type: TransactionType.transfer,
      title: 'Transferência',
      category: 'Transferência',
      amount: amount,
      date: date ?? DateTime.now(),
      account: '$from → $to',
    ));
    commit();
  }

  void payInvoice({
    required String cardId,
    required String accountName,
    DateTime? month,
  }) {
    final card = findCard(cardId);
    final account = findAccount(accountName);
    final targetMonth = month ?? selectedMonth;
    if (card == null || account == null) return;

    var amount = invoiceOutstandingForMonth(cardId, targetMonth);
    final now = DateTime.now();
    if (amount <= 0 && sameMonth(targetMonth, now) && card.used > 0) {
      amount = card.used;
    }
    if (amount <= 0) return;

    account.balance -= amount;
    card.used = (card.used - amount).clamp(0.0, double.infinity).toDouble();
    data.transactions.add(TransactionItem(
      id: FinanceStore.newId(),
      type: TransactionType.transfer,
      title: 'Pagamento fatura ${card.name}',
      category: 'Cartão',
      amount: amount,
      date: DateTime.now(),
      account: '$accountName → ${card.name}',
      cardId: card.id,
      invoiceMonth: DateTime(targetMonth.year, targetMonth.month),
    ));
    commit();
  }

  List<TransactionItem> cardTransactionsForMonth(
    String cardId,
    DateTime month,
  ) =>
      cardTransactionsForInvoiceMonth(cardId, month);
}
