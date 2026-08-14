import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

part 'store_transactions.dart';
part 'store_planning.dart';
part 'store_entities.dart';

class FinanceStore extends ChangeNotifier {
  static const _key = 'finora_data_v02';

  FinanceData data = emptyData();
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const defaultExpenseCategories = [
    'Alimentação', 'Transporte', 'Moradia', 'Saúde', 'Lazer', 'Compras',
    'Tecnologia', 'Pets', 'Educação', 'Serviços', 'Cartão', 'Outros',
  ];
  static const defaultIncomeCategories = [
    'Renda', 'Renda extra', 'Venda', 'Reembolso', 'Investimentos', 'Outros',
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
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, data.encode());
  }

  void commit() {
    _save();
    notifyListeners();
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

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
        id: newId(), name: accountName.trim(), type: 'Conta principal',
        balance: initialBalance,
      ));
    }
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

  double get cashBalance =>
      data.accounts.fold<double>(0, (sum, item) => sum + item.balance);
  double get reserveBalance =>
      data.reserves.fold<double>(0, (sum, item) => sum + item.saved);
  double get investmentBalance =>
      data.investments.fold<double>(0, (sum, item) => sum + item.amount);
  double get netWorth => cashBalance + reserveBalance + investmentBalance;

  List<TransactionItem> transactionsForMonth(DateTime month) {
    final items = data.transactions.where((e) => sameMonth(e.date, month)).toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  List<TransactionItem> get monthTransactions => transactionsForMonth(selectedMonth);

  double incomeForMonth(DateTime month) => transactionsForMonth(month)
      .where((e) => e.type == TransactionType.income)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double expenseForMonth(DateTime month) => transactionsForMonth(month)
      .where((e) => e.type == TransactionType.expense)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double get monthIncome => incomeForMonth(selectedMonth);
  double get monthExpense => expenseForMonth(selectedMonth);
  double get monthBalance => monthIncome - monthExpense;
  DateTime get previousSelectedMonth => DateTime(selectedMonth.year, selectedMonth.month - 1);
  double get previousMonthExpense => expenseForMonth(previousSelectedMonth);

  List<PlannedItem> plannedForMonth(DateTime month) {
    final items = data.planned.where((e) => sameMonth(e.date, month)).toList();
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  List<PlannedItem> get selectedPlanned => plannedForMonth(selectedMonth);
  double get plannedReceivable => selectedPlanned
      .where((e) => e.type == TransactionType.income)
      .fold<double>(0, (sum, item) => sum + item.amount);
  double get plannedPayable => selectedPlanned
      .where((e) => e.type == TransactionType.expense)
      .fold<double>(0, (sum, item) => sum + item.amount);

  double get suggestedGoalContribution => data.goals.fold<double>(
        0,
        (sum, goal) => sum +
            (goal.target - goal.saved).clamp(0.0, 200.0).toDouble(),
      );

  double get availableToSpend =>
      (cashBalance + plannedReceivable - plannedPayable - suggestedGoalContribution)
          .clamp(0.0, double.infinity)
          .toDouble();

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
      values.add(expenseForMonth(DateTime(selectedMonth.year, selectedMonth.month - i)));
    }
    return values;
  }

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

  static DateTime nextOccurrence(DateTime date, RecurrenceFrequency frequency) {
    if (frequency == RecurrenceFrequency.weekly) {
      return date.add(const Duration(days: 7));
    }
    if (frequency == RecurrenceFrequency.yearly) {
      return DateTime(date.year + 1, date.month, date.day);
    }
    return addMonths(date, 1);
  }

  static DateTime addMonths(DateTime date, int months) {
    final raw = date.month - 1 + months;
    final year = date.year + raw ~/ 12;
    final month = raw % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, date.day > lastDay ? lastDay : date.day);
  }

  static FinanceData emptyData() => FinanceData(
        darkMode: true,
        privacyMode: false,
        onboardingCompleted: false,
        primaryGoal: 'Controlar gastos',
        accounts: [], cards: [], transactions: [], planned: [], budgets: [],
        goals: [], reserves: [], investments: [], recurringRules: [],
        installmentPlans: [], categories: [],
      );

  static FinanceData demoData() {
    final now = DateTime.now();
    return FinanceData(
      darkMode: true,
      privacyMode: false,
      onboardingCompleted: true,
      primaryGoal: 'Planejar melhor',
      accounts: [AccountItem(id: 'a1', name: 'Conta principal', type: 'Conta', balance: 2400)],
      cards: [CardItem(id: 'c1', name: 'Cartão principal', limit: 3000, used: 620, closeDay: 25, dueDay: 5)],
      transactions: [
        TransactionItem(id: 't1', type: TransactionType.income, title: 'Salário', category: 'Renda', amount: 1850, date: DateTime(now.year, now.month, 5), account: 'Conta principal'),
        TransactionItem(id: 't2', type: TransactionType.expense, title: 'Mercado', category: 'Alimentação', amount: 176.40, date: DateTime(now.year, now.month, 7), account: 'Conta principal'),
        TransactionItem(id: 't3', type: TransactionType.expense, title: 'Streaming', category: 'Lazer', amount: 39.90, date: DateTime(now.year, now.month, 8), account: 'Cartão principal', paymentKind: PaymentKind.card, cardId: 'c1'),
      ],
      planned: [PlannedItem(id: 'p1', type: TransactionType.expense, title: 'Internet', category: 'Serviços', amount: 99, date: DateTime(now.year, now.month, 20), sourceName: 'Conta principal')],
      budgets: [BudgetItem(id: 'b1', category: 'Alimentação', limit: 500), BudgetItem(id: 'b2', category: 'Transporte', limit: 300)],
      goals: [GoalItem(id: 'g1', name: 'Objetivo', target: 2500, saved: 600, deadline: now.add(const Duration(days: 180)))],
      reserves: [ReserveItem(id: 'r1', name: 'Reserva de emergência', target: 6000, saved: 1400, months: 4)],
      investments: [InvestmentItem(id: 'i1', name: 'Tesouro Selic', assetClass: 'Renda fixa', amount: 900, estimatedReturn: 8.2)],
      recurringRules: [], installmentPlans: [], categories: [],
    );
  }
}
