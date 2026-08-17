part of 'store.dart';

extension FinanceStoreEntities on FinanceStore {
  void addBudget(String category, double limit) {
    final existing = data.budgets.where((e) => e.category == category);
    if (existing.isNotEmpty) {
      existing.first.limit = limit;
    } else {
      data.budgets.add(BudgetItem(
        id: FinanceStore.newId(),
        category: category,
        limit: limit,
      ));
    }
    commit();
  }

  void updateBudget(BudgetItem item, String category, double limit) {
    item.category = category;
    item.limit = limit;
    commit();
  }

  void deleteBudget(String id) {
    data.budgets.removeWhere((e) => e.id == id);
    commit();
  }

  void addCategory(String name, bool income) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final defaults = income
        ? FinanceStore.defaultIncomeCategories
        : FinanceStore.defaultExpenseCategories;
    if (defaults.contains(clean) ||
        data.categories.any((e) => e.income == income && e.name == clean)) {
      return;
    }
    data.categories.add(CategoryItem(
      id: FinanceStore.newId(),
      name: clean,
      income: income,
    ));
    commit();
  }

  void updateCategory(CategoryItem item, String name, bool income) {
    final oldName = item.name;
    item.name = name.trim();
    item.income = income;
    for (final tx in data.transactions.where((e) => e.category == oldName)) {
      tx.category = item.name;
    }
    for (final planned in data.planned.where((e) => e.category == oldName)) {
      planned.category = item.name;
    }
    for (final budget in data.budgets.where((e) => e.category == oldName)) {
      budget.category = item.name;
    }
    commit();
  }

  void deleteCategory(String id) {
    data.categories.removeWhere((e) => e.id == id);
    commit();
  }

  void addGoal(String name, double target, double saved, DateTime deadline) {
    data.goals.add(GoalItem(
      id: FinanceStore.newId(),
      name: name,
      target: target,
      saved: saved,
      deadline: deadline,
    ));
    commit();
  }

  void updateGoal(
    GoalItem item,
    String name,
    double target,
    double saved,
    DateTime deadline,
  ) {
    item.name = name;
    item.target = target;
    item.saved = saved.clamp(0.0, target).toDouble();
    item.deadline = deadline;
    commit();
  }

  void deleteGoal(String id) {
    data.goals.removeWhere((e) => e.id == id);
    commit();
  }

  void addReserve(String name, double target, double saved, {int months = 6}) {
    data.reserves.add(ReserveItem(
      id: FinanceStore.newId(),
      name: name,
      target: target,
      saved: saved,
      months: months,
    ));
    commit();
  }

  void updateReserve(
    ReserveItem item,
    String name,
    double target,
    double saved,
    int months,
  ) {
    item.name = name;
    item.target = target;
    item.saved = saved.clamp(0.0, target).toDouble();
    item.months = months.clamp(1, 60);
    commit();
  }

  void deleteReserve(String id) {
    data.reserves.removeWhere((e) => e.id == id);
    commit();
  }

  void addInvestment(
    String name,
    String assetClass,
    double amount,
    double estimatedReturn,
  ) {
    data.investments.add(InvestmentItem(
      id: FinanceStore.newId(),
      name: name,
      assetClass: assetClass,
      amount: amount,
      estimatedReturn: estimatedReturn,
    ));
    commit();
  }

  void updateInvestment(
    InvestmentItem item,
    String name,
    String assetClass,
    double amount,
    double estimatedReturn,
  ) {
    item.name = name;
    item.assetClass = assetClass;
    item.amount = amount;
    item.estimatedReturn = estimatedReturn;
    commit();
  }

  void deleteInvestment(String id) {
    data.investments.removeWhere((e) => e.id == id);
    commit();
  }

  void addAccount(String name, double balance, {String type = 'Conta digital'}) {
    data.accounts.add(AccountItem(
      id: FinanceStore.newId(),
      name: name,
      type: type,
      balance: balance,
    ));
    commit();
  }

  void updateAccount(
    AccountItem item,
    String name,
    String type,
    double balance,
  ) {
    final oldName = item.name;
    item.name = name;
    item.type = type;
    item.balance = balance;

    for (final tx in data.transactions.where((e) => e.account == oldName)) {
      tx.account = name;
    }
    for (final planned in data.planned.where((e) => e.sourceName == oldName)) {
      planned.sourceName = name;
    }
    for (final rule in data.recurringRules.where((e) => e.sourceName == oldName)) {
      rule.sourceName = name;
    }
    for (final plan in data.installmentPlans.where((e) => e.sourceName == oldName)) {
      plan.sourceName = name;
    }
    for (final card in data.cards.where((e) => e.defaultAccountName == oldName)) {
      card.defaultAccountName = name;
    }
    commit();
  }

  void deleteAccount(String id) {
    data.accounts.removeWhere((e) => e.id == id);
    commit();
  }

  void addCard(
    String name,
    double limit,
    double used,
    int closeDay,
    int dueDay, {
    String defaultAccountName = '',
  }) {
    data.cards.add(CardItem(
      id: FinanceStore.newId(),
      name: name,
      limit: limit,
      used: used,
      closeDay: closeDay.clamp(1, 31).toInt(),
      dueDay: dueDay.clamp(1, 31).toInt(),
      defaultAccountName: defaultAccountName,
    ));
    commit();
  }

  void updateCard(
    CardItem item,
    String name,
    double limit,
    double used,
    int closeDay,
    int dueDay,
    String defaultAccountName,
  ) {
    final oldName = item.name;
    item.name = name;
    item.limit = limit;
    item.used = used.clamp(0.0, double.infinity).toDouble();
    item.closeDay = closeDay.clamp(1, 31).toInt();
    item.dueDay = dueDay.clamp(1, 31).toInt();
    item.defaultAccountName = defaultAccountName;

    for (final tx in data.transactions.where((e) =>
        e.paymentKind == PaymentKind.card && e.cardId == item.id)) {
      tx.account = name;
      tx.invoiceMonth = invoiceMonthForPurchase(item, tx.date);
    }
    for (final planned in data.planned.where((e) =>
        e.paymentKind == PaymentKind.card && e.cardId == item.id)) {
      planned.sourceName = name;
      planned.invoiceMonth = invoiceMonthForPurchase(item, planned.date);
    }
    for (final rule in data.recurringRules.where((e) => e.cardId == item.id)) {
      rule.sourceName = name;
    }
    for (final plan in data.installmentPlans.where((e) => e.cardId == item.id)) {
      plan.sourceName = name;
    }
    for (final tx in data.transactions.where((e) => e.account == oldName)) {
      if (tx.paymentKind == PaymentKind.card) tx.account = name;
    }
    commit();
  }

  void deleteCard(String id) {
    data.cards.removeWhere((e) => e.id == id);
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
    final biometric = data.biometricEnabled;
    final notifications = data.notificationsEnabled;
    final notificationDays = data.notificationDaysBefore;
    data = demoData()
      ..darkMode = theme
      ..biometricEnabled = biometric
      ..notificationsEnabled = notifications
      ..notificationDaysBefore = notificationDays;
    currentMonth();
    commit();
  }

  void clearForRealUse() {
    final theme = data.darkMode;
    final biometric = data.biometricEnabled;
    final notifications = data.notificationsEnabled;
    final notificationDays = data.notificationDaysBefore;
    data = emptyData()
      ..darkMode = theme
      ..biometricEnabled = biometric
      ..notificationsEnabled = notifications
      ..notificationDaysBefore = notificationDays
      ..onboardingCompleted = true;
    final now = DateTime.now();
    data.trackingMonth = DateTime(now.year, now.month);
    data.trackingOpeningCash = 0;
    currentMonth();
    commit();
  }
}
