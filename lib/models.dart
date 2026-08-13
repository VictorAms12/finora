import 'dart:convert';

enum TransactionType { income, expense, transfer }

class TransactionItem {
  final String id;
  final TransactionType type;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String account;

  TransactionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.account,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'account': account,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        id: json['id'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransactionType.expense,
        ),
        title: json['title'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        account: json['account'] as String,
      );
}

class PlannedItem {
  final String id;
  final TransactionType type;
  final String title;
  final String category;
  final double amount;
  final DateTime date;

  PlannedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory PlannedItem.fromJson(Map<String, dynamic> json) => PlannedItem(
        id: json['id'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransactionType.expense,
        ),
        title: json['title'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}

class BudgetItem {
  final String id;
  final String category;
  final double limit;

  BudgetItem({required this.id, required this.category, required this.limit});

  Map<String, dynamic> toJson() => {'id': id, 'category': category, 'limit': limit};

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
        id: json['id'] as String,
        category: json['category'] as String,
        limit: (json['limit'] as num).toDouble(),
      );
}

class GoalItem {
  final String id;
  final String name;
  final double target;
  double saved;
  final DateTime deadline;

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

  factory GoalItem.fromJson(Map<String, dynamic> json) => GoalItem(
        id: json['id'] as String,
        name: json['name'] as String,
        target: (json['target'] as num).toDouble(),
        saved: (json['saved'] as num).toDouble(),
        deadline: DateTime.parse(json['deadline'] as String),
      );
}

class ReserveItem {
  final String id;
  final String name;
  final double target;
  double saved;
  final int months;

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

  factory ReserveItem.fromJson(Map<String, dynamic> json) => ReserveItem(
        id: json['id'] as String,
        name: json['name'] as String,
        target: (json['target'] as num).toDouble(),
        saved: (json['saved'] as num).toDouble(),
        months: (json['months'] as num).toInt(),
      );
}

class InvestmentItem {
  final String id;
  final String name;
  final String assetClass;
  final double amount;
  final double estimatedReturn;

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

  factory InvestmentItem.fromJson(Map<String, dynamic> json) => InvestmentItem(
        id: json['id'] as String,
        name: json['name'] as String,
        assetClass: json['assetClass'] as String,
        amount: (json['amount'] as num).toDouble(),
        estimatedReturn: (json['estimatedReturn'] as num).toDouble(),
      );
}

class AccountItem {
  final String id;
  final String name;
  final String type;
  double balance;

  AccountItem({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'type': type, 'balance': balance};

  factory AccountItem.fromJson(Map<String, dynamic> json) => AccountItem(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        balance: (json['balance'] as num).toDouble(),
      );
}

class CardItem {
  final String id;
  final String name;
  final double limit;
  double used;
  final int closeDay;
  final int dueDay;

  CardItem({
    required this.id,
    required this.name,
    required this.limit,
    required this.used,
    required this.closeDay,
    required this.dueDay,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'limit': limit,
        'used': used,
        'closeDay': closeDay,
        'dueDay': dueDay,
      };

  factory CardItem.fromJson(Map<String, dynamic> json) => CardItem(
        id: json['id'] as String,
        name: json['name'] as String,
        limit: (json['limit'] as num).toDouble(),
        used: (json['used'] as num).toDouble(),
        closeDay: (json['closeDay'] as num).toInt(),
        dueDay: (json['dueDay'] as num).toInt(),
      );
}

class FinanceData {
  bool darkMode;
  bool privacyMode;
  final List<TransactionItem> transactions;
  final List<PlannedItem> planned;
  final List<BudgetItem> budgets;
  final List<GoalItem> goals;
  final List<ReserveItem> reserves;
  final List<InvestmentItem> investments;
  final List<AccountItem> accounts;
  final List<CardItem> cards;

  FinanceData({
    required this.darkMode,
    required this.privacyMode,
    required this.transactions,
    required this.planned,
    required this.budgets,
    required this.goals,
    required this.reserves,
    required this.investments,
    required this.accounts,
    required this.cards,
  });

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
        'privacyMode': privacyMode,
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'planned': planned.map((e) => e.toJson()).toList(),
        'budgets': budgets.map((e) => e.toJson()).toList(),
        'goals': goals.map((e) => e.toJson()).toList(),
        'reserves': reserves.map((e) => e.toJson()).toList(),
        'investments': investments.map((e) => e.toJson()).toList(),
        'accounts': accounts.map((e) => e.toJson()).toList(),
        'cards': cards.map((e) => e.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory FinanceData.fromJson(Map<String, dynamic> json) => FinanceData(
        darkMode: json['darkMode'] as bool? ?? true,
        privacyMode: json['privacyMode'] as bool? ?? false,
        transactions: ((json['transactions'] as List?) ?? [])
            .map((e) => TransactionItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        planned: ((json['planned'] as List?) ?? [])
            .map((e) => PlannedItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        budgets: ((json['budgets'] as List?) ?? [])
            .map((e) => BudgetItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        goals: ((json['goals'] as List?) ?? [])
            .map((e) => GoalItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        reserves: ((json['reserves'] as List?) ?? [])
            .map((e) => ReserveItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        investments: ((json['investments'] as List?) ?? [])
            .map((e) => InvestmentItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        accounts: ((json['accounts'] as List?) ?? [])
            .map((e) => AccountItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        cards: ((json['cards'] as List?) ?? [])
            .map((e) => CardItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
