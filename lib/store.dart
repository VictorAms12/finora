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
  static const _backupKey = 'finora_data_v02_backup';

  static int _lastGeneratedId = 0;

  SharedPreferences? _prefs;
  Future<void> _saveChain = Future<void>.value();
  String? _lastQueuedRaw;

  final Map<String, List<TransactionItem>> _transactionsByMonth = {};
  final Map<String, double> _incomeByMonth = {};
  final Map<String, double> _expenseByMonth = {};
  final Map<String, Map<String, double>> _expensesByCategoryByMonth = {};

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

  Future<SharedPreferences> _preferences() async =>
      _prefs ??= await SharedPreferences.getInstance();

  FinanceData? _decodeData(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return FinanceData.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final prefs = await _preferences();
    final primaryRaw = prefs.getString(_key);
    final backupRaw = prefs.getString(_backupKey);

    var loaded = _decodeData(primaryRaw);
    var recoveredFromBackup = false;
    if (loaded == null && primaryRaw != null) {
      loaded = _decodeData(backupRaw);
      recoveredFromBackup = loaded != null;
    }

    data = loaded ?? emptyData();
    _invalidateCaches();
    refreshRecurringPlanning(persist: false);
    _ensureMonthlyTracking();

    final normalizedRaw = data.encode();
    if (primaryRaw != normalizedRaw || recoveredFromBackup) {
      await _persistRaw(
        normalizedRaw,
        rotateBackup: !recoveredFromBackup && _decodeData(primaryRaw) != null,
      );
    }

    notifyListeners();
  }

  Future<void> _persistRaw(
    String raw, {
    bool rotateBackup = true,
  }) async {
    final prefs = await _preferences();
    if (rotateBackup) {
      final previous = prefs.getString(_key);
      if (previous != null &&
          previous != raw &&
          _decodeData(previous) != null) {
        await prefs.setString(_backupKey, previous);
      }
    }
    await prefs.setString(_key, raw);
  }

  void _queueSave(String raw) {
    if (_lastQueuedRaw == raw) return;
    _lastQueuedRaw = raw;
    _saveChain = _saveChain
        .then((_) => _persistRaw(raw))
        .catchError((Object error, StackTrace stackTrace) {
      debugPrint('Finora: falha ao persistir dados: $error');
    });
  }

  Future<void> _save() async {
    _queueSave(data.encode());
    await flushPersistence();
  }

  Future<void> flushPersistence() async {
    await _saveChain;
  }

  void _invalidateCaches() {
    _transactionsByMonth.clear();
    _incomeByMonth.clear();
    _expenseByMonth.clear();
    _expensesByCategoryByMonth.clear();
  }

  @protected
  void onStateCommitted(String raw) {}

  void commit() {
    _invalidateCaches();
    _ensureMonthlyTracking();
    final raw = data.encode();
    _queueSave(raw);
    onStateCommitted(raw);
    notifyListeners();
  }

  static String newId() {
    final current = DateTime.now().microsecondsSinceEpoch;
    final next = current > _lastGeneratedId ? current : _lastGeneratedId + 1;
    _lastGeneratedId = next;
    return next.toString();
  }

  bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime monthStart(DateTime value) => DateTime(value.year, value.month);

  String _monthKey(DateTime value) => '${value.year}-${value.month}';

  bool isValidAmount(double value) => value.isFinite && value > 0;

  void selectMonth(DateTime value) {
    final normalized = DateTime(value.year, value.month);
    if (sameMonth(normalized, selectedMonth)) return;
    selectedMonth = normalized;
    notifyListeners();
  }

  void previousMonth() =>
      selectMonth(DateTime(selectedMonth.year, selectedMonth.month - 1));

  void nextMonth() =>
      selectMonth(DateTime(selectedMonth.year, selectedMonth.month + 1));

  void currentMonth() {
    final now = DateTime.now();
    selectMonth(DateTime(now.year, now.month));
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
    final cleanName = accountName.trim();
    if (cleanName.isNotEmpty && !accountNameExists(cleanName)) {
      data.accounts.add(AccountItem(
        id: newId(),
        name: cleanName,
        type: 'Conta principal',
        balance: initialBalance.isFinite ? initialBalance : 0,
      ));
    }
    final now = DateTime.now();
    data.trackingMonth = DateTime(now.year, now.month);
    data.trackingOpeningCash = cashBalance;
    commit();
  }

  void setDarkMode(bool value) {
    if (data.darkMode == value) return;
    data.darkMode = value;
    commit();
  }

  void setPrivacyMode(bool value) {
    if (data.privacyMode == value) return;
    data.privacyMode = value;
    commit();
  }

  void setBiometricEnabled(bool value) {
    if (data.biometricEnabled == value) return;
    data.biometricEnabled = value;
    commit();
  }

  void setNotificationsEnabled(bool value) {
    if (data.notificationsEnabled == value) return;
    data.notificationsEnabled = value;
    commit();
  }

  void setNotificationDaysBefore(int value) {
    final normalized = value.clamp(0, 7);
    if (data.notificationDaysBefore == normalized) return;
    data.notificationDaysBefore = normalized;
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
    final key = _monthKey(month);
    final cached = _transactionsByMonth[key];
    if (cached != null) return cached;

    final items =
        data.transactions.where((e) => sameMonth(e.date, month)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final result = List<TransactionItem>.unmodifiable(items);
    _transactionsByMonth[key] = result;
    return result;
  }

  List<TransactionItem> get monthTransactions =>
      transactionsForMonth(selectedMonth);

  double incomeForMonth(DateTime month) {
    final key = _monthKey(month);
    return _incomeByMonth.putIfAbsent(
      key,
      () => transactionsForMonth(month)
          .where((e) => e.type == TransactionType.income)
          .fold<double>(0, (sum, item) => sum + item.amount),
    );
  }

  double expenseForMonth(DateTime month) {
    final key = _monthKey(month);
    return _expenseByMonth.putIfAbsent(
      key,
      () => transactionsForMonth(month)
          .where((e) => e.type == TransactionType.expense)
          .fold<double>(0, (sum, item) => sum + item.amount),
    );
  }

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

  List<PlannedItem> get selectedPlanned {
    if (!selectedIsCurrent) return plannedForMonth(selectedMonth);
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    final items = data.planned
        .where((e) =>
            e.status == PlannedStatus.planned && e.date.isBefore(nextMonth))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

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

  double get cashAfterCommitments {
    final now = DateTime.now();
    return cashBalance +
        cashPlannedReceivableForMonth(now) -
        cashPlannedPayableForMonth(now);
  }

  double get currentCashShortfall =>
      (-cashAfterCommitments).clamp(0.0, double.infinity).toDouble();

  double get availableToSpend =>
      cashAfterCommitments.clamp(0.0, double.infinity).toDouble();

  double get availablePerDay {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (lastDay - now.day + 1).clamp(1, 31);
    return availableToSpend / remainingDays;
  }

  Map<String, double> get expensesByCategory {
    final key = _monthKey(selectedMonth);
    final cached = _expensesByCategoryByMonth[key];
    if (cached != null) return cached;

    final map = <String, double>{};
    for (final tx in monthTransactions) {
      if (tx.type == TransactionType.expense) {
        map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
      }
    }
    final result = Map<String, double>.unmodifiable(map);
    _expensesByCategoryByMonth[key] = result;
    return result;
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
    if (sameMonth(cursor, now)) {
      data.trackingOpeningCash = cashBalance - cashMovementForMonth(now);
      return;
    }
    if (cursor.isAfter(now)) {
      data.trackingMonth = now;
      data.trackingOpeningCash = cashBalance - cashMovementForMonth(now);
      return;
    }

    var opening = data.trackingOpeningCash;
    while (cursor.isBefore(now)) {
      final existing = snapshotForMonth(cursor);
      if (existing == null) {
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
        opening = existing.closingBalance;
      }
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    data.trackingMonth = now;
    data.trackingOpeningCash = cashBalance - cashMovementForMonth(now);
  }

  void rebuildSnapshotsFrom(DateTime month) {
    _invalidateCaches();
    final target = monthStart(month);
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    if (!target.isBefore(current)) {
      _ensureMonthlyTracking();
      return;
    }

    final targetSnapshot = snapshotForMonth(target);
    final previousSnapshot =
        snapshotForMonth(DateTime(target.year, target.month - 1));
    final opening = targetSnapshot?.openingBalance ?? previousSnapshot?.closingBalance;
    if (opening == null) return;

    data.snapshots.removeWhere((snapshot) =>
        !snapshot.month.isBefore(target) && snapshot.month.isBefore(current));

    var cursor = target;
    var rollingOpening = opening;
    while (cursor.isBefore(current)) {
      final closing = rollingOpening + cashMovementForMonth(cursor);
      data.snapshots.add(MonthlySnapshot(
        id: newId(),
        month: cursor,
        openingBalance: rollingOpening,
        closingBalance: closing,
        income: incomeForMonth(cursor),
        expense: expenseForMonth(cursor),
        createdAt: DateTime.now(),
      ));
      rollingOpening = closing;
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    data.snapshots.sort((a, b) => a.month.compareTo(b.month));
    data.trackingMonth = current;
    data.trackingOpeningCash = cashBalance - cashMovementForMonth(current);
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

  double invoiceDisplayOutstandingForMonth(String cardId, DateTime month) {
    var amount = invoiceOutstandingForMonth(cardId, month);
    if (sameMonth(month, DateTime.now())) {
      amount += manualCardOutstanding(cardId);
    }
    return amount;
  }

  double trackedCardOutstanding(String cardId) {
    final months = <String, DateTime>{};
    for (final tx in data.transactions) {
      if (tx.cardId != cardId) continue;
      if (tx.type == TransactionType.expense &&
          tx.paymentKind == PaymentKind.card) {
        final month = transactionInvoiceMonth(tx);
        months[_monthKey(month)] = month;
      } else if (tx.type == TransactionType.transfer &&
          tx.invoiceMonth != null &&
          tx.title.startsWith('Pagamento fatura')) {
        final month = monthStart(tx.invoiceMonth!);
        months[_monthKey(month)] = month;
      }
    }
    return months.values.fold<double>(
      0,
      (sum, month) => sum + invoiceOutstandingForMonth(cardId, month),
    );
  }

  double manualCardOutstanding(String cardId) {
    final card = findCard(cardId);
    if (card == null) return 0;
    return (card.used - trackedCardOutstanding(cardId))
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  double cardOutstandingDueForPlanningMonth(String cardId, DateTime month) {
    final target = monthStart(month);
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    if (!sameMonth(target, current)) {
      return invoiceOutstandingForMonth(cardId, target);
    }

    final months = <String, DateTime>{};
    for (final tx in data.transactions) {
      if (tx.cardId != cardId) continue;
      DateTime? invoice;
      if (tx.type == TransactionType.expense &&
          tx.paymentKind == PaymentKind.card) {
        invoice = transactionInvoiceMonth(tx);
      } else if (tx.type == TransactionType.transfer &&
          tx.invoiceMonth != null &&
          tx.title.startsWith('Pagamento fatura')) {
        invoice = monthStart(tx.invoiceMonth!);
      }
      if (invoice != null && !invoice.isAfter(current)) {
        months[_monthKey(invoice)] = invoice;
      }
    }

    var total = manualCardOutstanding(cardId);
    for (final invoice in months.values) {
      total += invoiceOutstandingForMonth(cardId, invoice);
    }
    return total;
  }

  List<String>? transferAccounts(TransactionItem item) {
    if (item.type != TransactionType.transfer) return null;
    final parts = item.account.split(' → ');
    if (parts.length != 2) return null;
    final from = parts[0].trim();
    final to = parts[1].trim();
    if (from.isEmpty || to.isEmpty) return null;
    return [from, to];
  }

  void _applyTransactionEffect(TransactionItem item, {required bool reverse}) {
    if (item.type == TransactionType.transfer) {
      final accounts = transferAccounts(item);
      final source = accounts == null ? null : findAccount(accounts[0]);

      if (item.title.startsWith('Pagamento fatura') && item.cardId != null) {
        final card = findCard(item.cardId);
        final delta = reverse ? item.amount : -item.amount;
        if (source != null) source.balance += delta;
        if (card != null) {
          card.used = (card.used + delta)
              .clamp(0.0, double.infinity)
              .toDouble();
        }
        return;
      }

      if (accounts == null) return;
      final target = findAccount(accounts[1]);
      if (source == null || target == null || source == target) return;
      final delta = reverse ? item.amount : -item.amount;
      source.balance += delta;
      target.balance -= delta;
      return;
    }

    final sign = reverse ? -1.0 : 1.0;
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
      final year = date.year + 1;
      final lastDay = DateTime(year, date.month + 1, 0).day;
      return DateTime(year, date.month, date.day.clamp(1, lastDay));
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
