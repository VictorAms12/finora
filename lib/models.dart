import 'dart:convert';

enum TransactionType { income, expense, transfer }
enum RecurrenceFrequency { weekly, monthly, yearly }
enum PaymentKind { account, card }
enum PlannedStatus { planned, settled, skipped }

class AccountItem {
  final String id;
  String name;
  String type;
  double balance;

  AccountItem({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'balance': balance,
      };

  factory AccountItem.fromJson(Map<String, dynamic> j) => AccountItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Conta',
        type: j['type'] as String? ?? 'Conta',
        balance: (j['balance'] as num? ?? 0).toDouble(),
      );
}

class CardItem {
  final String id;
  String name;
  double limit;
  double used;
  int closeDay;
  int dueDay;
  String defaultAccountName;

  CardItem({
    required this.id,
    required this.name,
    required this.limit,
    required this.used,
    required this.closeDay,
    required this.dueDay,
    this.defaultAccountName = '',
  });

  double get available =>
      (limit - used).clamp(0.0, double.infinity).toDouble();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'limit': limit,
        'used': used,
        'closeDay': closeDay,
        'dueDay': dueDay,
        'defaultAccountName': defaultAccountName,
      };

  factory CardItem.fromJson(Map<String, dynamic> j) => CardItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Cartão',
        limit: (j['limit'] as num? ?? 0).toDouble(),
        used: (j['used'] as num? ?? 0).toDouble(),
        closeDay: (j['closeDay'] as num? ?? 25).toInt(),
        dueDay: (j['dueDay'] as num? ?? 5).toInt(),
        defaultAccountName: j['defaultAccountName'] as String? ?? '',
      );
}

class CategoryItem {
  final String id;
  String name;
  bool income;

  CategoryItem({
    required this.id,
    required this.name,
    required this.income,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'income': income,
      };

  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Categoria',
        income: j['income'] as bool? ?? false,
      );
}

class TransactionItem {
  final String id;
  TransactionType type;
  String title;
  String category;
  double amount;
  DateTime date;
  String account;
  PaymentKind paymentKind;
  String? cardId;
  String note;
  String? recurrenceId;
  String? installmentId;
  int? installmentNumber;
  int? installmentTotal;
  DateTime? invoiceMonth;

  TransactionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.account,
    this.paymentKind = PaymentKind.account,
    this.cardId,
    this.note = '',
    this.recurrenceId,
    this.installmentId,
    this.installmentNumber,
    this.installmentTotal,
    this.invoiceMonth,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'account': account,
        'paymentKind': paymentKind.name,
        'cardId': cardId,
        'note': note,
        'recurrenceId': recurrenceId,
        'installmentId': installmentId,
        'installmentNumber': installmentNumber,
        'installmentTotal': installmentTotal,
        'invoiceMonth': invoiceMonth?.toIso8601String(),
      };

  factory TransactionItem.fromJson(Map<String, dynamic> j) => TransactionItem(
        id: j['id'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => TransactionType.expense,
        ),
        title: j['title'] as String? ?? 'Movimentação',
        category: j['category'] as String? ?? 'Outros',
        amount: (j['amount'] as num? ?? 0).toDouble(),
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        account: j['account'] as String? ?? '',
        paymentKind: PaymentKind.values.firstWhere(
          (e) => e.name == j['paymentKind'],
          orElse: () => PaymentKind.account,
        ),
        cardId: j['cardId'] as String?,
        note: j['note'] as String? ?? '',
        recurrenceId: j['recurrenceId'] as String?,
        installmentId: j['installmentId'] as String?,
        installmentNumber: (j['installmentNumber'] as num?)?.toInt(),
        installmentTotal: (j['installmentTotal'] as num?)?.toInt(),
        invoiceMonth: DateTime.tryParse(j['invoiceMonth'] as String? ?? ''),
      );
}

class PlannedItem {
  final String id;
  TransactionType type;
  String title;
  String category;
  double amount;
  DateTime date;
  String sourceName;
  PaymentKind paymentKind;
  String? cardId;
  String? recurrenceId;
  String? installmentId;
  int? installmentNumber;
  int? installmentTotal;
  DateTime? invoiceMonth;
  PlannedStatus status;

  PlannedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.sourceName = '',
    this.paymentKind = PaymentKind.account,
    this.cardId,
    this.recurrenceId,
    this.installmentId,
    this.installmentNumber,
    this.installmentTotal,
    this.invoiceMonth,
    this.status = PlannedStatus.planned,
  });

  bool get isPending => status == PlannedStatus.planned;
  bool get isOverdue => isPending && date.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'sourceName': sourceName,
        'paymentKind': paymentKind.name,
        'cardId': cardId,
        'recurrenceId': recurrenceId,
        'installmentId': installmentId,
        'installmentNumber': installmentNumber,
        'installmentTotal': installmentTotal,
        'invoiceMonth': invoiceMonth?.toIso8601String(),
        'status': status.name,
      };

  factory PlannedItem.fromJson(Map<String, dynamic> j) => PlannedItem(
        id: j['id'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => TransactionType.expense,
        ),
        title: j['title'] as String? ?? 'Previsto',
        category: j['category'] as String? ?? 'Outros',
        amount: (j['amount'] as num? ?? 0).toDouble(),
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        sourceName: j['sourceName'] as String? ?? '',
        paymentKind: PaymentKind.values.firstWhere(
          (e) => e.name == j['paymentKind'],
          orElse: () => PaymentKind.account,
        ),
        cardId: j['cardId'] as String?,
        recurrenceId: j['recurrenceId'] as String?,
        installmentId: j['installmentId'] as String?,
        installmentNumber: (j['installmentNumber'] as num?)?.toInt(),
        installmentTotal: (j['installmentTotal'] as num?)?.toInt(),
        invoiceMonth: DateTime.tryParse(j['invoiceMonth'] as String? ?? ''),
        status: PlannedStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => PlannedStatus.planned,
        ),
      );
}

class BudgetItem {
  final String id;
  String category;
  double limit;

  BudgetItem({required this.id, required this.category, required this.limit});

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'limit': limit,
      };

  factory BudgetItem.fromJson(Map<String, dynamic> j) => BudgetItem(
        id: j['id'] as String,
        category: j['category'] as String? ?? 'Outros',
        limit: (j['limit'] as num? ?? 0).toDouble(),
      );
}

class GoalItem {
  final String id;
  String name;
  double target;
  double saved;
  DateTime deadline;

  GoalItem({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    required this.deadline,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target': target,
        'saved': saved,
        'deadline': deadline.toIso8601String(),
      };

  factory GoalItem.fromJson(Map<String, dynamic> j) => GoalItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Meta',
        target: (j['target'] as num? ?? 0).toDouble(),
        saved: (j['saved'] as num? ?? 0).toDouble(),
        deadline: DateTime.tryParse(j['deadline'] as String? ?? '') ??
            DateTime.now(),
      );
}

class ReserveItem {
  final String id;
  String name;
  double target;
  double saved;
  int months;

  ReserveItem({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    required this.months,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target': target,
        'saved': saved,
        'months': months,
      };

  factory ReserveItem.fromJson(Map<String, dynamic> j) => ReserveItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Reserva',
        target: (j['target'] as num? ?? 0).toDouble(),
        saved: (j['saved'] as num? ?? 0).toDouble(),
        months: (j['months'] as num? ?? 6).toInt(),
      );
}

class InvestmentItem {
  final String id;
  String name;
  String assetClass;
  double amount;
  double estimatedReturn;

  InvestmentItem({
    required this.id,
    required this.name,
    required this.assetClass,
    required this.amount,
    required this.estimatedReturn,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'assetClass': assetClass,
        'amount': amount,
        'estimatedReturn': estimatedReturn,
      };

  factory InvestmentItem.fromJson(Map<String, dynamic> j) => InvestmentItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Investimento',
        assetClass: j['assetClass'] as String? ?? 'Renda fixa',
        amount: (j['amount'] as num? ?? 0).toDouble(),
        estimatedReturn: (j['estimatedReturn'] as num? ?? 0).toDouble(),
      );
}

class RecurringRule {
  final String id;
  TransactionType type;
  String title;
  String category;
  double amount;
  String sourceName;
  PaymentKind paymentKind;
  String? cardId;
  DateTime startDate;
  RecurrenceFrequency frequency;
  bool active;
  DateTime? endDate;
  int? maxOccurrences;

  RecurringRule({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.sourceName,
    required this.paymentKind,
    this.cardId,
    required this.startDate,
    required this.frequency,
    this.active = true,
    this.endDate,
    this.maxOccurrences,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'category': category,
        'amount': amount,
        'sourceName': sourceName,
        'paymentKind': paymentKind.name,
        'cardId': cardId,
        'startDate': startDate.toIso8601String(),
        'frequency': frequency.name,
        'active': active,
        'endDate': endDate?.toIso8601String(),
        'maxOccurrences': maxOccurrences,
      };

  factory RecurringRule.fromJson(Map<String, dynamic> j) => RecurringRule(
        id: j['id'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => TransactionType.expense,
        ),
        title: j['title'] as String? ?? 'Recorrência',
        category: j['category'] as String? ?? 'Outros',
        amount: (j['amount'] as num? ?? 0).toDouble(),
        sourceName:
            j['sourceName'] as String? ?? j['account'] as String? ?? '',
        paymentKind: PaymentKind.values.firstWhere(
          (e) => e.name == j['paymentKind'],
          orElse: () => PaymentKind.account,
        ),
        cardId: j['cardId'] as String?,
        startDate: DateTime.tryParse(j['startDate'] as String? ?? '') ??
            DateTime.now(),
        frequency: RecurrenceFrequency.values.firstWhere(
          (e) => e.name == j['frequency'],
          orElse: () => RecurrenceFrequency.monthly,
        ),
        active: j['active'] as bool? ?? true,
        endDate: DateTime.tryParse(j['endDate'] as String? ?? ''),
        maxOccurrences: (j['maxOccurrences'] as num?)?.toInt(),
      );
}

class InstallmentPlan {
  final String id;
  String title;
  String category;
  String sourceName;
  PaymentKind paymentKind;
  String? cardId;
  double totalAmount;
  int installments;
  DateTime startDate;

  InstallmentPlan({
    required this.id,
    required this.title,
    required this.category,
    required this.sourceName,
    required this.paymentKind,
    this.cardId,
    required this.totalAmount,
    required this.installments,
    required this.startDate,
  });

  double get installmentValue =>
      installments <= 0 ? 0.0 : totalAmount / installments;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'sourceName': sourceName,
        'paymentKind': paymentKind.name,
        'cardId': cardId,
        'totalAmount': totalAmount,
        'installments': installments,
        'startDate': startDate.toIso8601String(),
      };

  factory InstallmentPlan.fromJson(Map<String, dynamic> j) => InstallmentPlan(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Parcelamento',
        category: j['category'] as String? ?? 'Compras',
        sourceName:
            j['sourceName'] as String? ?? j['account'] as String? ?? '',
        paymentKind: PaymentKind.values.firstWhere(
          (e) => e.name == j['paymentKind'],
          orElse: () => PaymentKind.account,
        ),
        cardId: j['cardId'] as String?,
        totalAmount: (j['totalAmount'] as num? ?? 0).toDouble(),
        installments: (j['installments'] as num? ?? 1).toInt(),
        startDate: DateTime.tryParse(j['startDate'] as String? ?? '') ??
            DateTime.now(),
      );
}

class MonthlySnapshot {
  final String id;
  DateTime month;
  double openingBalance;
  double closingBalance;
  double income;
  double expense;
  DateTime createdAt;

  MonthlySnapshot({
    required this.id,
    required this.month,
    required this.openingBalance,
    required this.closingBalance,
    required this.income,
    required this.expense,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'month': month.toIso8601String(),
        'openingBalance': openingBalance,
        'closingBalance': closingBalance,
        'income': income,
        'expense': expense,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MonthlySnapshot.fromJson(Map<String, dynamic> j) => MonthlySnapshot(
        id: j['id'] as String,
        month: DateTime.tryParse(j['month'] as String? ?? '') ?? DateTime.now(),
        openingBalance: (j['openingBalance'] as num? ?? 0).toDouble(),
        closingBalance: (j['closingBalance'] as num? ?? 0).toDouble(),
        income: (j['income'] as num? ?? 0).toDouble(),
        expense: (j['expense'] as num? ?? 0).toDouble(),
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class FinanceData {
  bool darkMode;
  bool privacyMode;
  bool biometricEnabled;
  bool notificationsEnabled;
  int notificationDaysBefore;
  bool onboardingCompleted;
  String primaryGoal;
  DateTime? trackingMonth;
  double trackingOpeningCash;
  final List<AccountItem> accounts;
  final List<CardItem> cards;
  final List<TransactionItem> transactions;
  final List<PlannedItem> planned;
  final List<BudgetItem> budgets;
  final List<GoalItem> goals;
  final List<ReserveItem> reserves;
  final List<InvestmentItem> investments;
  final List<RecurringRule> recurringRules;
  final List<InstallmentPlan> installmentPlans;
  final List<CategoryItem> categories;
  final List<MonthlySnapshot> snapshots;

  FinanceData({
    required this.darkMode,
    required this.privacyMode,
    required this.biometricEnabled,
    required this.notificationsEnabled,
    required this.notificationDaysBefore,
    required this.onboardingCompleted,
    required this.primaryGoal,
    required this.trackingMonth,
    required this.trackingOpeningCash,
    required this.accounts,
    required this.cards,
    required this.transactions,
    required this.planned,
    required this.budgets,
    required this.goals,
    required this.reserves,
    required this.investments,
    required this.recurringRules,
    required this.installmentPlans,
    required this.categories,
    required this.snapshots,
  });

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
        'privacyMode': privacyMode,
        'biometricEnabled': biometricEnabled,
        'notificationsEnabled': notificationsEnabled,
        'notificationDaysBefore': notificationDaysBefore,
        'onboardingCompleted': onboardingCompleted,
        'primaryGoal': primaryGoal,
        'trackingMonth': trackingMonth?.toIso8601String(),
        'trackingOpeningCash': trackingOpeningCash,
        'accounts': accounts.map((e) => e.toJson()).toList(),
        'cards': cards.map((e) => e.toJson()).toList(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'planned': planned.map((e) => e.toJson()).toList(),
        'budgets': budgets.map((e) => e.toJson()).toList(),
        'goals': goals.map((e) => e.toJson()).toList(),
        'reserves': reserves.map((e) => e.toJson()).toList(),
        'investments': investments.map((e) => e.toJson()).toList(),
        'recurringRules': recurringRules.map((e) => e.toJson()).toList(),
        'installmentPlans': installmentPlans.map((e) => e.toJson()).toList(),
        'categories': categories.map((e) => e.toJson()).toList(),
        'snapshots': snapshots.map((e) => e.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory FinanceData.fromJson(Map<String, dynamic> j) => FinanceData(
        darkMode: j['darkMode'] as bool? ?? true,
        privacyMode: j['privacyMode'] as bool? ?? false,
        biometricEnabled: j['biometricEnabled'] as bool? ?? false,
        notificationsEnabled: j['notificationsEnabled'] as bool? ?? false,
        notificationDaysBefore:
            (j['notificationDaysBefore'] as num? ?? 2).toInt(),
        onboardingCompleted: j['onboardingCompleted'] as bool? ?? false,
        primaryGoal: j['primaryGoal'] as String? ?? 'Controlar gastos',
        trackingMonth:
            DateTime.tryParse(j['trackingMonth'] as String? ?? ''),
        trackingOpeningCash:
            (j['trackingOpeningCash'] as num? ?? 0).toDouble(),
        accounts: ((j['accounts'] as List?) ?? [])
            .map((e) => AccountItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        cards: ((j['cards'] as List?) ?? [])
            .map((e) => CardItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        transactions: ((j['transactions'] as List?) ?? [])
            .map((e) =>
                TransactionItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        planned: ((j['planned'] as List?) ?? [])
            .map((e) => PlannedItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        budgets: ((j['budgets'] as List?) ?? [])
            .map((e) => BudgetItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        goals: ((j['goals'] as List?) ?? [])
            .map((e) => GoalItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        reserves: ((j['reserves'] as List?) ?? [])
            .map((e) => ReserveItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        investments: ((j['investments'] as List?) ?? [])
            .map((e) =>
                InvestmentItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        recurringRules: ((j['recurringRules'] as List?) ?? [])
            .map((e) =>
                RecurringRule.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        installmentPlans: ((j['installmentPlans'] as List?) ?? [])
            .map((e) =>
                InstallmentPlan.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        categories: ((j['categories'] as List?) ?? [])
            .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        snapshots: ((j['snapshots'] as List?) ?? [])
            .map((e) =>
                MonthlySnapshot.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
