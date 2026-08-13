import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class FinanceStore extends ChangeNotifier {
  static const _storageKey = 'finora_data_v01';

  FinanceData data = seedData();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        data = FinanceData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        data = seedData();
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, data.encode());
  }

  void commit() {
    _save();
    notifyListeners();
  }

  AccountItem? _findAccount(String name) {
    for (final account in data.accounts) {
      if (account.name == name) return account;
    }
    return null;
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
      data.accounts.fold<double>(0, (sum, e) => sum + e.balance);

  double get reserveBalance =>
      data.reserves.fold<double>(0, (sum, e) => sum + e.saved);

  double get investmentBalance =>
      data.investments.fold<double>(0, (sum, e) => sum + e.amount);

  double get netWorth => cashBalance + reserveBalance + investmentBalance;

  List<TransactionItem> get currentMonthTransactions => data.transactions
      .where((t) => t.date.year == 2026 && t.date.month == 8)
      .toList();

  double get monthIncome => currentMonthTransactions
      .where((t) => t.type == TransactionType.income)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get monthExpense => currentMonthTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get monthBalance => monthIncome - monthExpense;

  double get plannedPayable => data.planned
      .where((e) => e.type == TransactionType.expense)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get plannedReceivable => data.planned
      .where((e) => e.type == TransactionType.income)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get plannedBudgetLimit =>
      data.budgets.fold<double>(0, (sum, e) => sum + e.limit);

  double get availableToSpend {
    final plannedGoalContribution = data.goals.fold<double>(
      0,
      (sum, goal) =>
          sum + (goal.target - goal.saved).clamp(0.0, 200.0).toDouble(),
    );
    return (cashBalance - plannedPayable - plannedGoalContribution)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (final tx in currentMonthTransactions) {
      if (tx.type != TransactionType.expense) continue;
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    return map;
  }

  void addTransaction(TransactionItem item) {
    data.transactions.add(item);
    final account = _findAccount(item.account);
    if (account != null) {
      if (item.type == TransactionType.income) account.balance += item.amount;
      if (item.type == TransactionType.expense) account.balance -= item.amount;
    }
    commit();
  }

  void transfer({
    required double amount,
    required String from,
    required String to,
    required String title,
  }) {
    final source = _findAccount(from);
    final target = _findAccount(to);
    if (source != null) source.balance -= amount;
    if (target != null) target.balance += amount;

    data.transactions.add(
      TransactionItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: TransactionType.transfer,
        title: title,
        category: 'Transferência',
        amount: amount,
        date: DateTime.now(),
        account: '$from → $to',
      ),
    );
    commit();
  }

  void addBudget(BudgetItem item) {
    data.budgets.add(item);
    commit();
  }

  void addGoal(GoalItem item) {
    data.goals.add(item);
    commit();
  }

  void addReserve(ReserveItem item) {
    data.reserves.add(item);
    commit();
  }

  void addInvestment(InvestmentItem item) {
    data.investments.add(item);
    commit();
  }

  void addAccount(AccountItem item) {
    data.accounts.add(item);
    commit();
  }

  void addCard(CardItem item) {
    data.cards.add(item);
    commit();
  }

  void contributeGoal(String id, double value) {
    final goal = data.goals.firstWhere((e) => e.id == id);
    goal.saved = (goal.saved + value).clamp(0.0, goal.target).toDouble();
    commit();
  }

  void contributeReserve(String id, double value) {
    final reserve = data.reserves.firstWhere((e) => e.id == id);
    reserve.saved =
        (reserve.saved + value).clamp(0.0, reserve.target).toDouble();
    commit();
  }

  void resetDemo() {
    data = seedData();
    commit();
  }

  static FinanceData seedData() => FinanceData(
        darkMode: true,
        privacyMode: false,
        accounts: [
          AccountItem(
              id: 'a1',
              name: 'Nubank',
              type: 'Conta digital',
              balance: 1420),
          AccountItem(
              id: 'a2',
              name: 'Inter',
              type: 'Conta corrente',
              balance: 850),
          AccountItem(
              id: 'a3', name: 'Carteira', type: 'Dinheiro', balance: 180),
          AccountItem(
              id: 'a4',
              name: 'Poupança',
              type: 'Poupança',
              balance: 2500),
        ],
        cards: [
          CardItem(
              id: 'c1',
              name: 'Nubank',
              limit: 3000,
              used: 820,
              closeDay: 25,
              dueDay: 3),
          CardItem(
              id: 'c2',
              name: 'Inter',
              limit: 1800,
              used: 310,
              closeDay: 20,
              dueDay: 28),
        ],
        transactions: [
          TransactionItem(
              id: 't1',
              type: TransactionType.income,
              title: 'Salário',
              category: 'Renda',
              amount: 1650,
              date: DateTime(2026, 8, 5),
              account: 'Nubank'),
          TransactionItem(
              id: 't2',
              type: TransactionType.expense,
              title: 'Internet',
              category: 'Moradia',
              amount: 99,
              date: DateTime(2026, 8, 10),
              account: 'Nubank'),
          TransactionItem(
              id: 't3',
              type: TransactionType.expense,
              title: 'Combustível',
              category: 'Transporte',
              amount: 100,
              date: DateTime(2026, 8, 11),
              account: 'Inter'),
          TransactionItem(
              id: 't4',
              type: TransactionType.expense,
              title: 'Restaurante',
              category: 'Alimentação',
              amount: 42.90,
              date: DateTime(2026, 8, 12),
              account: 'Nubank'),
          TransactionItem(
              id: 't5',
              type: TransactionType.expense,
              title: 'Streaming',
              category: 'Lazer',
              amount: 16,
              date: DateTime(2026, 8, 3),
              account: 'Nubank'),
          TransactionItem(
              id: 't6',
              type: TransactionType.income,
              title: 'Venda de eletrônico',
              category: 'Renda extra',
              amount: 280,
              date: DateTime(2026, 8, 8),
              account: 'Inter'),
          TransactionItem(
              id: 't7',
              type: TransactionType.expense,
              title: 'Mercado',
              category: 'Alimentação',
              amount: 148.70,
              date: DateTime(2026, 8, 7),
              account: 'Inter'),
          TransactionItem(
              id: 't8',
              type: TransactionType.expense,
              title: 'Farmácia',
              category: 'Saúde',
              amount: 63.40,
              date: DateTime(2026, 8, 6),
              account: 'Nubank'),
        ],
        planned: [
          PlannedItem(
              id: 'p1',
              type: TransactionType.expense,
              title: 'Fatura Nubank',
              category: 'Cartão',
              amount: 820,
              date: DateTime(2026, 8, 28)),
          PlannedItem(
              id: 'p2',
              type: TransactionType.expense,
              title: 'Internet móvel',
              category: 'Comunicação',
              amount: 25,
              date: DateTime(2026, 8, 20)),
          PlannedItem(
              id: 'p3',
              type: TransactionType.income,
              title: 'Freelance',
              category: 'Renda extra',
              amount: 350,
              date: DateTime(2026, 8, 22)),
        ],
        budgets: [
          BudgetItem(id: 'b1', category: 'Alimentação', limit: 500),
          BudgetItem(id: 'b2', category: 'Transporte', limit: 300),
          BudgetItem(id: 'b3', category: 'Lazer', limit: 250),
          BudgetItem(id: 'b4', category: 'Saúde', limit: 180),
        ],
        goals: [
          GoalItem(
              id: 'g1',
              name: 'Novo celular',
              target: 2000,
              saved: 1200,
              deadline: DateTime(2026, 10, 30)),
          GoalItem(
              id: 'g2',
              name: 'Viagem',
              target: 4000,
              saved: 850,
              deadline: DateTime(2027, 7, 1)),
          GoalItem(
              id: 'g3',
              name: 'Computador',
              target: 5000,
              saved: 500,
              deadline: DateTime(2027, 12, 1)),
        ],
        reserves: [
          ReserveItem(
              id: 'r1',
              name: 'Reserva de emergência',
              target: 9000,
              saved: 2500,
              months: 6),
        ],
        investments: [
          InvestmentItem(
              id: 'i1',
              name: 'Tesouro Selic',
              assetClass: 'Renda fixa',
              amount: 2100,
              estimatedReturn: 8.5),
          InvestmentItem(
              id: 'i2',
              name: 'CDB 110% CDI',
              assetClass: 'Renda fixa',
              amount: 1300,
              estimatedReturn: 7.2),
          InvestmentItem(
              id: 'i3',
              name: 'FIIs',
              assetClass: 'Fundos imobiliários',
              amount: 900,
              estimatedReturn: 5.1),
          InvestmentItem(
              id: 'i4',
              name: 'ETF',
              assetClass: 'ETF',
              amount: 500,
              estimatedReturn: 4.3),
        ],
      );
}
