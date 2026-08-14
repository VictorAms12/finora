part of 'store.dart';

extension FinanceStoreEntities on FinanceStore {
  void addBudget(String category, double limit) {
    final existing = data.budgets.where((e) => e.category == category);
    if (existing.isNotEmpty) {
      existing.first.limit = limit;
    } else {
      data.budgets.add(BudgetItem(id: FinanceStore.newId(), category: category, limit: limit));
    }
    commit();
  }

  void addCategory(String name, bool income) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final defaults = income
        ? FinanceStore.defaultIncomeCategories
        : FinanceStore.defaultExpenseCategories;
    if (defaults.contains(clean) ||
        data.categories.any((e) => e.income == income && e.name == clean)) return;
    data.categories.add(CategoryItem(id: FinanceStore.newId(), name: clean, income: income));
    commit();
  }

  void deleteCategory(String id) {
    data.categories.removeWhere((e) => e.id == id);
    commit();
  }

  void addGoal(String name, double target, double saved, DateTime deadline) {
    data.goals.add(GoalItem(id: FinanceStore.newId(), name: name, target: target, saved: saved, deadline: deadline));
    commit();
  }

  void addReserve(String name, double target, double saved) {
    data.reserves.add(ReserveItem(id: FinanceStore.newId(), name: name, target: target, saved: saved, months: 6));
    commit();
  }

  void addInvestment(String name, String assetClass, double amount, double estimatedReturn) {
    data.investments.add(InvestmentItem(
      id: FinanceStore.newId(), name: name, assetClass: assetClass,
      amount: amount, estimatedReturn: estimatedReturn,
    ));
    commit();
  }

  void addAccount(String name, double balance) {
    data.accounts.add(AccountItem(id: FinanceStore.newId(), name: name, type: 'Conta', balance: balance));
    commit();
  }

  void addCard(String name, double limit, double used, int closeDay, int dueDay) {
    data.cards.add(CardItem(
      id: FinanceStore.newId(), name: name, limit: limit, used: used,
      closeDay: closeDay.clamp(1, 31).toInt(),
      dueDay: dueDay.clamp(1, 31).toInt(),
    ));
    commit();
  }

  void contributeGoal(String id, double value) {
    final item = data.goals.firstWhere((e) => e.id == id);
    item.saved = (item.saved + value).clamp(0.0, item.target).toDouble();
    commit();
  }

  void contributeReserve(String id, double value) {
    final item = data.reserves.firstWhere((e) => e.id == id);
    item.saved = (item.saved + value).clamp(0.0, item.target).toDouble();
    commit();
  }

  void loadDemo() {
    final theme = data.darkMode;
    data = FinanceStore.demoData()..darkMode = theme;
    currentMonth();
    commit();
  }

  void clearForRealUse() {
    final theme = data.darkMode;
    data = FinanceStore.emptyData()
      ..darkMode = theme
      ..onboardingCompleted = true;
    currentMonth();
    commit();
  }
}
