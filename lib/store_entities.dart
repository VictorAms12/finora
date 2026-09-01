part of 'store.dart';

extension FinanceStoreEntities on FinanceStore {
  String _normalizedName(String value) => value.trim().toLowerCase();

  bool accountNameExists(String name, {String? exceptId}) {
    final normalized = _normalizedName(name);
    if (normalized.isEmpty) return false;
    return data.accounts.any((account) =>
        account.id != exceptId && _normalizedName(account.name) == normalized);
  }

  bool _historicalAccountNameUsed(String name) {
    final normalized = _normalizedName(name);
    for (final tx in data.transactions) {
      if (tx.type == TransactionType.transfer) {
        final pair = transferAccounts(tx);
        if (pair != null && pair.any((value) => _normalizedName(value) == normalized)) {
          return true;
        }
      } else if (_normalizedName(tx.account) == normalized) {
        return true;
      }
    }
    return false;
  }

  bool _categoryNameExists(String name, bool income, {String? exceptId}) {
    final normalized = _normalizedName(name);
    final defaults = income
        ? FinanceStore.defaultIncomeCategories
        : FinanceStore.defaultExpenseCategories;
    if (defaults.any((value) => _normalizedName(value) == normalized)) return true;
    return data.categories.any((category) =>
        category.id != exceptId &&
        category.income == income &&
        _normalizedName(category.name) == normalized);
  }

  bool addBudget(String category, double limit) {
    if (!isValidAmount(limit)) return false;
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
    return true;
  }

  bool updateBudget(BudgetItem item, String category, double limit) {
    if (!isValidAmount(limit)) return false;
    item.category = category;
    item.limit = limit;
    commit();
    return true;
  }

  void deleteBudget(String id) {
    data.budgets.removeWhere((e) => e.id == id);
    commit();
  }

  bool addCategory(String name, bool income) {
    final clean = name.trim();
    if (clean.isEmpty || _categoryNameExists(clean, income)) return false;
    data.categories.add(CategoryItem(
      id: FinanceStore.newId(),
      name: clean,
      income: income,
    ));
    commit();
    return true;
  }

  bool updateCategory(CategoryItem item, String name, bool income) {
    final clean = name.trim();
    if (clean.isEmpty ||
        _categoryNameExists(clean, income, exceptId: item.id)) {
      return false;
    }

    final oldName = item.name;
    if (income != item.income) {
      final referenced = data.transactions.any((e) => e.category == oldName) ||
          data.planned.any((e) => e.category == oldName) ||
          data.recurringRules.any((e) => e.category == oldName) ||
          data.installmentPlans.any((e) => e.category == oldName) ||
          data.budgets.any((e) => e.category == oldName);
      if (referenced) return false;
    }
    item.name = clean;
    item.income = income;
    for (final tx in data.transactions.where((e) => e.category == oldName)) {
      tx.category = clean;
    }
    for (final planned in data.planned.where((e) => e.category == oldName)) {
      planned.category = clean;
    }
    for (final rule in data.recurringRules.where((e) => e.category == oldName)) {
      rule.category = clean;
    }
    for (final plan in data.installmentPlans.where((e) => e.category == oldName)) {
      plan.category = clean;
    }

    if (income) {
      data.budgets.removeWhere((e) => e.category == oldName);
    } else {
      for (final budget in data.budgets.where((e) => e.category == oldName)) {
        budget.category = clean;
      }
    }
    commit();
    return true;
  }

  bool deleteCategory(String id) {
    final index = data.categories.indexWhere((e) => e.id == id);
    if (index == -1) return false;
    final name = data.categories[index].name;
    final inUse = data.budgets.any((e) => e.category == name) ||
        data.planned.any((e) =>
            e.status == PlannedStatus.planned && e.category == name) ||
        data.recurringRules.any((e) => e.active && e.category == name);
    if (inUse) return false;
    data.categories.removeAt(index);
    commit();
    return true;
  }

  bool addGoal(String name, double target, double saved, DateTime deadline) {
    final clean = name.trim();
    if (clean.isEmpty || !isValidAmount(target)) return false;
    data.goals.add(GoalItem(
      id: FinanceStore.newId(),
      name: clean,
      target: target,
      saved: saved.isFinite
          ? saved.clamp(0.0, double.infinity).toDouble()
          : 0,
      deadline: deadline,
    ));
    commit();
    return true;
  }

  bool updateGoal(
    GoalItem item,
    String name,
    double target,
    double saved,
    DateTime deadline,
  ) {
    final clean = name.trim();
    if (clean.isEmpty || !isValidAmount(target)) return false;
    item.name = clean;
    item.target = target;
    item.saved = saved.isFinite
        ? saved.clamp(0.0, double.infinity).toDouble()
        : 0;
    item.deadline = deadline;
    commit();
    return true;
  }

  void deleteGoal(String id) {
    data.goals.removeWhere((e) => e.id == id);
    commit();
  }

  bool addReserve(
    String name,
    double target,
    double saved, {
    int months = 6,
  }) {
    final clean = name.trim();
    if (clean.isEmpty || !isValidAmount(target) || !saved.isFinite || saved < 0) {
      return false;
    }
    data.reserves.add(ReserveItem(
      id: FinanceStore.newId(),
      name: clean,
      target: target,
      saved: saved,
      months: months.clamp(1, 60),
    ));
    commit();
    return true;
  }

  bool updateReserve(
    ReserveItem item,
    String name,
    double target,
    double saved,
    int months,
  ) {
    final clean = name.trim();
    if (clean.isEmpty || !isValidAmount(target) || !saved.isFinite || saved < 0) {
      return false;
    }
    item.name = clean;
    item.target = target;
    item.saved = saved;
    item.months = months.clamp(1, 60);
    commit();
    return true;
  }

  void deleteReserve(String id) {
    data.reserves.removeWhere((e) => e.id == id);
    commit();
  }

  bool addInvestment(
    String name,
    String assetClass,
    double amount,
    double estimatedReturn,
  ) {
    final clean = name.trim();
    if (clean.isEmpty || !isValidAmount(amount) || !estimatedReturn.isFinite) {
      return false;
    }
    data.investments.add(InvestmentItem(
      id: FinanceStore.newId(),
      name: clean,
      assetClass: assetClass,
      amount: amount,
      estimatedReturn: estimatedReturn,
    ));
    commit();
    return true;
  }

  bool updateInvestment(
    InvestmentItem item,
    String name,
    String assetClass,
    double amount,
    double estimatedReturn,
  ) {
    final clean = name.trim();
    if (clean.isEmpty || !isValidAmount(amount) || !estimatedReturn.isFinite) {
      return false;
    }
    item.name = clean;
    item.assetClass = assetClass;
    item.amount = amount;
    item.estimatedReturn = estimatedReturn;
    commit();
    return true;
  }

  void deleteInvestment(String id) {
    data.investments.removeWhere((e) => e.id == id);
    commit();
  }

  bool addAccount(
    String name,
    double balance, {
    String type = 'Conta digital',
  }) {
    final clean = name.trim();
    if (clean.isEmpty ||
        accountNameExists(clean) ||
        _historicalAccountNameUsed(clean) ||
        !balance.isFinite) {
      return false;
    }
    data.accounts.add(AccountItem(
      id: FinanceStore.newId(),
      name: clean,
      type: type,
      balance: balance,
    ));
    commit();
    return true;
  }

  bool updateAccount(
    AccountItem item,
    String name,
    String type,
    double balance,
  ) {
    final clean = name.trim();
    if (clean.isEmpty ||
        accountNameExists(clean, exceptId: item.id) ||
        !balance.isFinite) {
      return false;
    }

    final oldName = item.name;
    item.name = clean;
    item.type = type;
    item.balance = balance;

    for (final tx in data.transactions) {
      if (tx.type == TransactionType.transfer) {
        final accounts = transferAccounts(tx);
        if (accounts != null) {
          final from = accounts[0] == oldName ? clean : accounts[0];
          final to = accounts[1] == oldName ? clean : accounts[1];
          tx.account = '$from → $to';
        }
      } else if (tx.account == oldName) {
        tx.account = clean;
      }
    }
    for (final planned in data.planned) {
      if (planned.sourceName == oldName) planned.sourceName = clean;
      if (planned.destinationName == oldName) planned.destinationName = clean;
    }
    for (final rule in data.recurringRules.where((e) => e.sourceName == oldName)) {
      rule.sourceName = clean;
    }
    for (final plan in data.installmentPlans.where((e) => e.sourceName == oldName)) {
      plan.sourceName = clean;
    }
    for (final card in data.cards.where((e) => e.defaultAccountName == oldName)) {
      card.defaultAccountName = clean;
    }
    commit();
    return true;
  }

  bool deleteAccount(String id) {
    final index = data.accounts.indexWhere((e) => e.id == id);
    if (index == -1) return false;
    final removedName = data.accounts[index].name;
    final hasPending = data.planned.any((item) =>
        item.status == PlannedStatus.planned &&
        (item.sourceName == removedName || item.destinationName == removedName));
    final hasRecurring = data.recurringRules.any((rule) =>
        rule.active &&
        rule.paymentKind == PaymentKind.account &&
        rule.sourceName == removedName);
    if (hasPending || hasRecurring) return false;

    data.accounts.removeAt(index);
    for (final card in data.cards.where((e) => e.defaultAccountName == removedName)) {
      card.defaultAccountName = '';
    }
    commit();
    return true;
  }

  bool addCard(
    String name,
    double limit,
    double used,
    int closeDay,
    int dueDay, {
    String defaultAccountName = '',
  }) {
    final clean = name.trim();
    if (clean.isEmpty || !isValidAmount(limit) || !used.isFinite) return false;
    data.cards.add(CardItem(
      id: FinanceStore.newId(),
      name: clean,
      limit: limit,
      used: used.clamp(0.0, double.infinity).toDouble(),
      closeDay: closeDay.clamp(1, 31),
      dueDay: dueDay.clamp(1, 31),
      defaultAccountName: defaultAccountName,
    ));
    commit();
    return true;
  }

  bool updateCard(
    CardItem item,
    String name,
    double limit,
    double used,
    int closeDay,
    int dueDay,
    String defaultAccountName,
  ) {
    final clean = name.trim();
    if (clean.isEmpty || !isValidAmount(limit) || !used.isFinite) return false;
    final tracked = trackedCardOutstanding(item.id);
    if (used < -0.005 || used + 0.005 < tracked) return false;

    final oldName = item.name;
    item.name = clean;
    item.limit = limit;
    item.used = used.clamp(0.0, double.infinity).toDouble();
    item.closeDay = closeDay.clamp(1, 31);
    item.dueDay = dueDay.clamp(1, 31);
    item.defaultAccountName = defaultAccountName;

    // Faturas históricas são fatos. Alterar fechamento/vencimento só afeta
    // compromissos ainda pendentes; compras já realizadas mantêm competência.
    for (final tx in data.transactions.where((e) =>
        e.paymentKind == PaymentKind.card && e.cardId == item.id)) {
      tx.account = clean;
    }
    for (final tx in data.transactions.where((e) =>
        e.type == TransactionType.transfer &&
        e.cardId == item.id &&
        e.title.startsWith('Pagamento fatura'))) {
      final pair = transferAccounts(tx);
      if (pair != null) tx.account = '${pair[0]} → $clean';
      tx.title = 'Pagamento fatura $clean';
    }
    for (final planned in data.planned.where((e) => e.cardId == item.id)) {
      planned.sourceName = clean;
      if (planned.status == PlannedStatus.planned) {
        planned.invoiceMonth = invoiceMonthForPurchase(item, planned.date);
      }
    }
    for (final rule in data.recurringRules.where((e) => e.cardId == item.id)) {
      rule.sourceName = clean;
    }
    for (final plan in data.installmentPlans.where((e) => e.cardId == item.id)) {
      plan.sourceName = clean;
    }
    for (final tx in data.transactions.where((e) => e.account == oldName)) {
      if (tx.paymentKind == PaymentKind.card) tx.account = clean;
    }
    commit();
    return true;
  }

  bool deleteCard(String id) {
    final exists = data.cards.any((e) => e.id == id);
    if (!exists) return false;
    final hasPending = data.planned.any((item) =>
        item.status == PlannedStatus.planned && item.cardId == id);
    final hasRecurring =
        data.recurringRules.any((rule) => rule.active && rule.cardId == id);
    if (hasPending || hasRecurring) return false;
    data.cards.removeWhere((e) => e.id == id);
    commit();
    return true;
  }

  void contributeGoal(String id, double value) {
    if (!isValidAmount(value)) return;
    final index = data.goals.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final item = data.goals[index];
    item.saved = (item.saved + value).clamp(0.0, double.infinity).toDouble();
    commit();
  }

  void contributeReserve(String id, double value) {
    if (!isValidAmount(value)) return;
    final index = data.reserves.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final item = data.reserves[index];
    item.saved += value;
    commit();
  }

  bool withdrawReserve(String id, double value) {
    if (!isValidAmount(value)) return false;
    final index = data.reserves.indexWhere((e) => e.id == id);
    if (index == -1) return false;
    final item = data.reserves[index];
    if (value > item.saved) return false;
    item.saved -= value;
    if (item.saved.abs() < 0.000001) item.saved = 0;
    commit();
    return true;
  }

  void loadDemo() {
    final theme = data.darkMode;
    final privacy = data.privacyMode;
    final biometric = data.biometricEnabled;
    final notifications = data.notificationsEnabled;
    final notificationDays = data.notificationDaysBefore;
    data = demoData()
      ..darkMode = theme
      ..privacyMode = privacy
      ..biometricEnabled = biometric
      ..notificationsEnabled = notifications
      ..notificationDaysBefore = notificationDays;
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    commit();
  }

  void clearForRealUse() {
    final theme = data.darkMode;
    final privacy = data.privacyMode;
    final biometric = data.biometricEnabled;
    final notifications = data.notificationsEnabled;
    final notificationDays = data.notificationDaysBefore;
    data = emptyData()
      ..darkMode = theme
      ..privacyMode = privacy
      ..biometricEnabled = biometric
      ..notificationsEnabled = notifications
      ..notificationDaysBefore = notificationDays
      ..onboardingCompleted = true;
    final now = DateTime.now();
    data.trackingMonth = DateTime(now.year, now.month);
    data.trackingOpeningCash = 0;
    selectedMonth = DateTime(now.year, now.month);
    commit();
  }
}
