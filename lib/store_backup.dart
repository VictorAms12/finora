part of 'store.dart';

extension FinanceStoreBackup on FinanceStore {
  static const _backupPrefix = 'FINORA-BACKUP-1:';
  static const _backupVersion = 1;

  String exportBackupText() {
    final envelope = <String, dynamic>{
      'format': 'finora-backup',
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data.toJson(),
    };
    final json = jsonEncode(envelope);
    return '$_backupPrefix${base64Url.encode(utf8.encode(json))}';
  }

  Future<bool> restoreBackupText(String input) async {
    try {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return false;

      dynamic decoded;
      if (trimmed.startsWith(_backupPrefix)) {
        final payload = trimmed.substring(_backupPrefix.length);
        decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      } else {
        decoded = jsonDecode(trimmed);
      }

      if (decoded is! Map) return false;
      final map = Map<String, dynamic>.from(decoded);

      if (map['format'] == 'finora-backup') {
        final version = (map['version'] as num?)?.toInt() ?? 0;
        if (version < 1 || version > _backupVersion) return false;
      }

      final rawData = map['format'] == 'finora-backup' ? map['data'] : map;
      if (rawData is! Map) return false;

      // Só substitui o estado atual depois de validar toda a estrutura.
      final restored = FinanceData.fromJson(Map<String, dynamic>.from(rawData));
      data = restored;
      _invalidateCaches();
      refreshRecurringPlanning(persist: false);
      final now = DateTime.now();
      selectedMonth = DateTime(now.year, now.month);
      commit();
      await _save();
      return true;
    } catch (_) {
      return false;
    }
  }
}

FinanceData emptyData() => FinanceData(
  darkMode: true,
  privacyMode: false,
  biometricEnabled: false,
  notificationsEnabled: false,
  notificationDaysBefore: 2,
  onboardingCompleted: false,
  primaryGoal: 'Controlar gastos',
  copilotMemoryEnabled: true,
  copilotMemories: [],
  trackingMonth: null,
  trackingOpeningCash: 0,
  accounts: [],
  cards: [],
  transactions: [],
  planned: [],
  budgets: [],
  goals: [],
  reserves: [],
  investments: [],
  recurringRules: [],
  installmentPlans: [],
  categories: [],
  snapshots: [],
);

FinanceData demoData() {
  final now = DateTime.now();
  return FinanceData(
    darkMode: true,
    privacyMode: false,
    biometricEnabled: false,
    notificationsEnabled: false,
    notificationDaysBefore: 2,
    onboardingCompleted: true,
    primaryGoal: 'Planejar melhor',
    copilotMemoryEnabled: true,
    copilotMemories: [],
    trackingMonth: DateTime(now.year, now.month),
    trackingOpeningCash: 2400,
    accounts: [
      AccountItem(
        id: 'a1',
        name: 'Conta principal',
        type: 'Conta digital',
        balance: 2400,
      ),
    ],
    cards: [
      CardItem(
        id: 'c1',
        name: 'Cartão principal',
        limit: 3000,
        used: 620,
        closeDay: 25,
        dueDay: 5,
        defaultAccountName: 'Conta principal',
      ),
    ],
    transactions: [
      TransactionItem(
        id: 't1',
        type: TransactionType.income,
        title: 'Salário',
        category: 'Renda',
        amount: 1850,
        date: DateTime(now.year, now.month, 5),
        account: 'Conta principal',
      ),
      TransactionItem(
        id: 't2',
        type: TransactionType.expense,
        title: 'Mercado',
        category: 'Alimentação',
        amount: 176.40,
        date: DateTime(now.year, now.month, 7),
        account: 'Conta principal',
      ),
      TransactionItem(
        id: 't3',
        type: TransactionType.expense,
        title: 'Streaming',
        category: 'Lazer',
        amount: 39.90,
        date: DateTime(now.year, now.month, 8),
        account: 'Cartão principal',
        paymentKind: PaymentKind.card,
        cardId: 'c1',
        invoiceMonth: DateTime(now.year, now.month + 1),
      ),
    ],
    planned: [
      PlannedItem(
        id: 'p1',
        type: TransactionType.expense,
        title: 'Internet',
        category: 'Serviços',
        amount: 99,
        date: DateTime(now.year, now.month, 20),
        sourceName: 'Conta principal',
      ),
    ],
    budgets: [
      BudgetItem(id: 'b1', category: 'Alimentação', limit: 500),
      BudgetItem(id: 'b2', category: 'Transporte', limit: 300),
    ],
    goals: [
      GoalItem(
        id: 'g1',
        name: 'Objetivo',
        target: 2500,
        saved: 600,
        deadline: now.add(const Duration(days: 180)),
      ),
    ],
    reserves: [
      ReserveItem(
        id: 'r1',
        name: 'Reserva de emergência',
        target: 6000,
        saved: 1400,
        months: 4,
      ),
    ],
    investments: [
      InvestmentItem(
        id: 'i1',
        name: 'Tesouro Selic',
        assetClass: 'Renda fixa',
        amount: 900,
        estimatedReturn: 8.2,
      ),
    ],
    recurringRules: [],
    installmentPlans: [],
    categories: [],
    snapshots: [],
  );
}
