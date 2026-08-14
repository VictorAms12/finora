part of 'store.dart';

extension FinanceStoreTransactions on FinanceStore {
  void addTransaction(TransactionItem item) {
    if (item.paymentKind == PaymentKind.card &&
        item.type == TransactionType.expense &&
        item.invoiceMonth == null) {
      final card = findCard(item.cardId);
      if (card != null) {
        item.invoiceMonth = invoiceMonthForPurchase(card, item.date);
      }
    }
    data.transactions.add(item);
    _applyTransactionEffect(item, reverse: false);
    commit();
  }

  void updateTransaction(TransactionItem before, TransactionItem after) {
    final index = data.transactions.indexWhere((e) => e.id == before.id);
    if (index == -1) return;

    if (after.paymentKind == PaymentKind.card &&
        after.type == TransactionType.expense) {
      final card = findCard(after.cardId);
      if (card != null) {
        after.invoiceMonth = invoiceMonthForPurchase(card, after.date);
      }
    } else {
      after.invoiceMonth = null;
    }

    _applyTransactionEffect(before, reverse: true);
    data.transactions[index] = after;
    _applyTransactionEffect(after, reverse: false);
    commit();
  }

  void deleteTransaction(TransactionItem item) {
    _applyTransactionEffect(item, reverse: true);
    data.transactions.removeWhere((e) => e.id == item.id);
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

    final amount = invoiceOutstandingForMonth(cardId, targetMonth);
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
