import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

part 'store_transactions.dart';
part 'store_planning.dart';
part 'store_entities.dart';
part 'store_backup.dart';

class FinanceStore extends ChangeNotifier {
  static const _key = 'finora_data_v02';

  FinanceData data = emptyData();
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const defaultExpenseCategories = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Lazer',
    'Compras',
    'Tecnologia',
    'Pets',
    'Educação',
    'Serviços',
    'Cartão',
    'Outros',
  ];

  static const defaultIncomeCategories = [
    'Renda',
    'Renda extra',
    'Venda',
    'Reembolso',
    'Investimentos',
    'Outros',
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        data = FinanceData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        data = emptyData();
      }
    }
    _ensureMonthlyTracking();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, data.encode());
  }

  void commit() {
    _ensureMonthlyTracking();
    _save();
    notifyListeners();
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  DateTime monthStart(DateTime value) => DateTime(value.year, value.month);

  void previousMonth() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    notifyListeners();
  }

  void currentMonth() {
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    notifyListeners();
  }

  bool get selectedIsCurrent {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  bool get selectedIsFuture {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    return selectedMonth.isAfter(now);
  }

  bool get selectedIsPast => !selectedIsCurrent && !selectedIsFuture;

  AccountItem? findAccount(String name) {
    for (final item in data.accounts) {
      if (item.name == name) return item;
    }
    return null;
  }

  CardItem? findCard(String? id) {
    if (id == null) return null;
    for (final item in data.cards) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<String> get expenseCategories {
    final custom = data.categories
        .where((e) => !e.income)
        .map((e) => e.name)
        .where((e) => !defaultExpenseCategories.contains(e));
    return [...defaultExpenseCategories, ...custom];
  }

  List<String> get incomeCategories {
    final custom = data.categories
        .where((e) => e.income)
        .map((e) => e.name)
        .where((e) => !defaultIncomeCategories.contains(e));
    return [...defaultIncomeCategories, ...custom];
  }

  void finishOnboarding({
    required String accountName,
    required double initialBalance,
    required String primaryGoal,
  }) {
    data.onboardingCompleted = true;
    data.primaryGoal = primaryGoal;
    if (accountName.trim().isNotEmpty) {
      data.accounts.add(AccountItem(
        id: newId(),
        name: accountName.trim(),
        type: 'Conta principal',
        balance: initialBalance,
      ));
    }
    final now = DateTime.now();
    data.trackingMonth = DateTime(now.year, now.month);
    data.trackingOpeningCash = cashBalance;
    commit();
  }

  void setDarkMode(bool value) {
    data.darkMode = value;
    commit();
  }

  void setPrivacyMode(bool value) {
    data.privacyMode = value;
    commit();
  }

  void setBiometricEnabled(bool value) {
    data.biometricEnabled = value;
    commit();
  }

  void setNotificationsEnabled(bool value) {
    data.notificationsEnabled = value;
    commit();
  }

  void setNotificationDaysBefore(int value) {
    data.notificationDaysBefore = value.clamp(0, 7);
    commit();
  }

  double get cashBalance =>
      data.accounts.fold<double>(0, (sum, item) => sum + item.balance);
  double get reserveBalance =>
      data.reserves.fold<double>(0, (sum, item) => sum + item.saved);
  double get investmentBalance =>
      data.investments.fold<double>(0, (sum, item) => sum + item.amount);
  double get netWorth => cashBalance + reserveBalance + investmentBalance;

  List<TransactionItem> transactionsForMonth(DateTime month) {
    final items =
        data.transactions.where((e) => sameMonth(e.date, month)).toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  List<TransactionItem> get monthTransactions =>
      transactionsForMonth(selectedMonth);

  double incomeForMonth(DateTime month) => transactionsForMonth(month)
      .where((e) => e.type == TransactionType.income)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double expenseForMonth(DateTime month) => transactionsForMonth(month)
      .where((e) => e.type == TransactionType.expense)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double get monthIncome => incomeForMonth(selectedMonth);
  double get monthExpense => expenseForMonth(selectedMonth);
  double get monthBalance => monthIncome - monthExpense;

  DateTime get previousSelectedMonth =>
      DateTime(selectedMonth.year, selectedMonth.month - 1);
  double get previousMonthExpense => expenseForMonth(previousSelectedMonth);

  List<PlannedItem> allPlannedForMonth(DateTime month) {
    final items = data.planned.where((e) => sameMonth(e.date, month)).toList();
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  List<PlannedItem> plannedForMonth(DateTime month) => allPlannedForMonth(month)
      .where((e) => e.status == PlannedStatus.planned)
      .toList();

  List<PlannedItem> get selectedPlanned => plannedForMonth(selectedMonth);
  List<PlannedItem> get selectedPlannedHistory => allPlannedForMonth(selectedMonth);

  double plannedReceivableForMonth(DateTime month) => plannedForMonth(month)
      .where((e) => e.type == TransactionType.income)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double plannedPayableForMonth(DateTime month) => plannedForMonth(month)
      .where((e) => e.type == TransactionType.expense)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double get plannedReceivable => plannedReceivableForMonth(selectedMonth);
  double get plannedPayable => plannedPayableForMonth(selectedMonth);

  int get overduePlannedCount => data.planned
      .where((e) => e.status == PlannedStatus.planned && e.isOverdue)
      .length;

  double get suggestedGoalContribution => data.goals.fold<double>(
        0,
        (sum, goal) =>
            sum + (goal.target - goal.saved).clamp(0.0, 200.0).toDouble(),
      );

  double get availableToSpend {
    final now = DateTime.now();
    final receivable = cashPlannedReceivableForMonth(now);
    final payable = cashPlannedPayableForMonth(now);
    return (cashBalance + receivable - payable - suggestedGoalContribution)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  double get availablePerDay {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (lastDay - now.day + 1).clamp(1, 31);
    return availableToSpend / remainingDays;
  }

  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (final tx in monthTransactions) {
      if (tx.type == TransactionType.expense) {
        map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
      }
    }
    return map;
  }

  List<double> get lastSixMonthExpenses {
    final values = <double>[];
    for (var i = 5; i >= 0; i--) {
      values.add(
        expenseForMonth(DateTime(selectedMonth.year, selectedMonth.month - i)),
      );
    }
    return values;
  }

  MonthlySnapshot? snapshotForMonth(DateTime month) {
    for (final item in data.snapshots) {
      if (sameMonth(item.month, month)) return item;
    }
    return null;
  }

  double cashMovementForMonth(DateTime month) {
    var result = 0.0;
    for (final tx in transactionsForMonth(month)) {
      if (tx.type == TransactionType.income &&
          tx.paymentKind == PaymentKind.account) {
        result += tx.amount;
      } else if (tx.type == TransactionType.expense &&
          tx.paymentKind == PaymentKind.account) {
        result -= tx.amount;
      } else if (tx.type == TransactionType.transfer &&
          tx.title.startsWith('Pagamento fatura')) {
        result -= tx.amount;
      }
    }
    return result;
  }

  void _ensureMonthlyTracking() {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    if (data.trackingMonth == null) {
      data.trackingMonth = now;
      data.trackingOpeningCash = cashBalance - cashMovementForMonth(now);
      return;
    }

    var cursor = monthStart(data.trackingMonth!);
    if (!cursor.isBefore(now)) return;

    var opening = data.trackingOpeningCash;
    while (cursor.isBefore(now)) {
      if (snapshotForMonth(cursor) == null) {
        final closing = opening + cashMovementForMonth(cursor);
        data.snapshots.add(MonthlySnapshot(
          id: newId(),
          month: cursor,
          openingBalance: opening,
          closingBalance: closing,
          income: incomeForMonth(cursor),
          expense: expenseForMonth(cursor),
          createdAt: DateTime.now(),
        ));
        opening = closing;
      } else {
        opening = snapshotForMonth(cursor)!.closingBalance;
      }
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    data.trackingMonth = now;
    data.trackingOpeningCash = opening;
  }

  double projectedOpeningForMonth(DateTime month) {
    final target = monthStart(month);
    final now = DateTime(DateTime.now().year, DateTime.now().month);

    if (target.isBefore(now)) {
      return snapshotForMonth(target)?.openingBalance ?? 0;
    }
    if (sameMonth(target, now)) return cashBalance;
    final previous = DateTime(target.year, target.month - 1);
    return projectedClosingForMonth(previous);
  }

  double projectedClosingForMonth(DateTime month) {
    final target = monthStart(month);
    final now = DateTime(DateTime.now().year, DateTime.now().month);

    if (target.isBefore(now)) {
      final snapshot = snapshotForMonth(target);
      if (snapshot != null) return snapshot.closingBalance;
      return incomeForMonth(target) - expenseForMonth(target);
    }

    var balance = cashBalance;
    var cursor = now;
    while (!cursor.isAfter(target)) {
      balance += cashPlannedReceivableForMonth(cursor);
      balance -= cashPlannedPayableForMonth(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return balance;
  }

  double get selectedProjectedOpening => projectedOpeningForMonth(selectedMonth);
  double get selectedProjectedClosing => projectedClosingForMonth(selectedMonth);

  DateTime invoiceMonthForPurchase(CardItem card, DateTime purchaseDate) {
    var closeMonth = DateTime(purchaseDate.year, purchaseDate.month);
    if (purchaseDate.day > card.closeDay) {
      closeMonth = DateTime(closeMonth.year, closeMonth.month + 1);
    }
    final dueSameMonth = card.dueDay > card.closeDay;
    final dueMonth = dueSameMonth
        ? closeMonth
        : DateTime(closeMonth.year, closeMonth.month + 1);
    return DateTime(dueMonth.year, dueMonth.month);
  }

  DateTime transactionInvoiceMonth(TransactionItem tx) {
    if (tx.invoiceMonth != null) return monthStart(tx.invoiceMonth!);
    final card = findCard(tx.cardId);
    if (card == null) return monthStart(tx.date);
    return invoiceMonthForPurchase(card, tx.date);
  }

  List<TransactionItem> cardTransactionsForInvoiceMonth(
    String cardId,
    DateTime month,
  ) {
    final items = data.transactions.where((tx) {
      return tx.type == TransactionType.expense &&
          tx.paymentKind == PaymentKind.card &&
          tx.cardId == cardId &&
          sameMonth(transactionInvoiceMonth(tx), month);
    }).toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  double invoiceTotalForMonth(String cardId, DateTime month) =>
      cardTransactionsForInvoiceMonth(cardId, month)
          .fold<double>(0, (sum, item) => sum + item.amount);

  double invoicePaidForMonth(String cardId, DateTime month) => data.transactions
      .where((tx) =>
          tx.type == TransactionType.transfer &&
          tx.cardId == cardId &&
          tx.invoiceMonth != null &&
          sameMonth(tx.invoiceMonth!, month) &&
          tx.title.startsWith('Pagamento fatura'))
      .fold<double>(0, (sum, item) => sum + item.amount);

  double invoiceOutstandingForMonth(String cardId, DateTime month) =>
      (invoiceTotalForMonth(cardId, month) - invoicePaidForMonth(cardId, month))
          .clamp(0.0, double.infinity)
          .toDouble();

  void _applyTransactionEffect(TransactionItem item, {required bool reverse}) {
    final sign = reverse ? -1.0 : 1.0;
    if (item.type == TransactionType.transfer) return;

    if (item.paymentKind == PaymentKind.card &&
        item.type == TransactionType.expense) {
      final card = findCard(item.cardId);
      if (card != null) {
        card.used += item.amount * sign;
        if (card.used < 0) card.used = 0;
      }
      return;
    }

    final account = findAccount(item.account);
    if (account == null) return;
    if (item.type == TransactionType.income) {
      account.balance += item.amount * sign;
    } else if (item.type == TransactionType.expense) {
      account.balance -= item.amount * sign;
    }
  }

  static DateTime nextOccurrence(
    DateTime date,
    RecurrenceFrequency frequency,
  ) {
    if (frequency == RecurrenceFrequency.weekly) {
      return date.add(const Duration(days: 7));
    }
    if (frequency == RecurrenceFrequency.yearly) {
      return DateTime(date.year + 1, date.month, date.day);
    }
    return addMonths(date, 1);
  }

  static DateTime addMonths(DateTime date, int months) {
    final rawMonth = date.month + months;
    final targetYear = date.year + ((rawMonth - 1) ~/ 12);
    final targetMonth = ((rawMonth - 1) % 12) + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    return DateTime(targetYear, targetMonth, date.day.clamp(1, lastDay));
  }
}
