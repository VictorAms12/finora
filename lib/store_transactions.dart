part of 'store.dart';

extension FinanceStoreTransactions on FinanceStore {
  void addTransaction(TransactionItem item) {
    data.transactions.add(item);
    _applyTransactionEffect(item, reverse: false);
    commit();
  }

  void updateTransaction(TransactionItem before, TransactionItem after) {
    final index = data.transactions.indexWhere((e) => e.id == before.id);
    if (index == -1) return;
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

  void transfer({required double amount, required String from, required String to}) {
    final source = findAccount(from);
    final target = findAccount(to);
    if (source == null || target == null || source == target) return;
    source.balance -= amount;
    target.balance += amount;
    data.transactions.add(TransactionItem(
      id: FinanceStore.newId(), type: TransactionType.transfer,
      title: 'Transferência', category: 'Transferência', amount: amount,
      date: DateTime.now(), account: '$from → $to',
    ));
    commit();
  }

  void payInvoice({required String cardId, required String accountName}) {
    final card = findCard(cardId);
    final account = findAccount(accountName);
    if (card == null || account == null || card.used <= 0) return;
    final amount = card.used;
    account.balance -= amount;
    card.used = 0;
    data.transactions.add(TransactionItem(
      id: FinanceStore.newId(), type: TransactionType.transfer,
      title: 'Pagamento fatura ${card.name}', category: 'Cartão', amount: amount,
      date: DateTime.now(), account: '$accountName → ${card.name}',
    ));
    commit();
  }

  List<TransactionItem> cardTransactionsForMonth(String cardId, DateTime month) =>
      transactionsForMonth(month)
          .where((e) => e.paymentKind == PaymentKind.card &&
              e.cardId == cardId && e.type == TransactionType.expense)
          .toList();
}
