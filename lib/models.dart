import 'dart:convert';

enum TransactionType { income, expense, transfer }
enum RecurrenceFrequency { weekly, monthly, yearly }

class AccountItem {
  final String id; String name; String type; double balance;
  AccountItem({required this.id, required this.name, required this.type, required this.balance});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'type':type,'balance':balance};
  factory AccountItem.fromJson(Map<String,dynamic> j)=>AccountItem(id:j['id'],name:j['name'],type:j['type'],balance:(j['balance'] as num).toDouble());
}

class CardItem {
  final String id; String name; double limit; double used; int closeDay; int dueDay;
  CardItem({required this.id,required this.name,required this.limit,required this.used,required this.closeDay,required this.dueDay});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'limit':limit,'used':used,'closeDay':closeDay,'dueDay':dueDay};
  factory CardItem.fromJson(Map<String,dynamic> j)=>CardItem(id:j['id'],name:j['name'],limit:(j['limit'] as num).toDouble(),used:(j['used'] as num).toDouble(),closeDay:(j['closeDay'] as num).toInt(),dueDay:(j['dueDay'] as num).toInt());
}

class TransactionItem {
  final String id; TransactionType type; String title; String category; double amount; DateTime date; String account;
  String? recurrenceId; String? installmentId; int? installmentNumber; int? installmentTotal;
  TransactionItem({required this.id,required this.type,required this.title,required this.category,required this.amount,required this.date,required this.account,this.recurrenceId,this.installmentId,this.installmentNumber,this.installmentTotal});
  Map<String,dynamic> toJson()=>{'id':id,'type':type.name,'title':title,'category':category,'amount':amount,'date':date.toIso8601String(),'account':account,'recurrenceId':recurrenceId,'installmentId':installmentId,'installmentNumber':installmentNumber,'installmentTotal':installmentTotal};
  factory TransactionItem.fromJson(Map<String,dynamic> j)=>TransactionItem(id:j['id'],type:TransactionType.values.firstWhere((e)=>e.name==j['type'],orElse:()=>TransactionType.expense),title:j['title'],category:j['category'],amount:(j['amount'] as num).toDouble(),date:DateTime.parse(j['date']),account:j['account'],recurrenceId:j['recurrenceId'],installmentId:j['installmentId'],installmentNumber:(j['installmentNumber'] as num?)?.toInt(),installmentTotal:(j['installmentTotal'] as num?)?.toInt());
}

class PlannedItem {
  final String id; TransactionType type; String title; String category; double amount; DateTime date;
  String? recurrenceId; String? installmentId; int? installmentNumber; int? installmentTotal;
  PlannedItem({required this.id,required this.type,required this.title,required this.category,required this.amount,required this.date,this.recurrenceId,this.installmentId,this.installmentNumber,this.installmentTotal});
  Map<String,dynamic> toJson()=>{'id':id,'type':type.name,'title':title,'category':category,'amount':amount,'date':date.toIso8601String(),'recurrenceId':recurrenceId,'installmentId':installmentId,'installmentNumber':installmentNumber,'installmentTotal':installmentTotal};
  factory PlannedItem.fromJson(Map<String,dynamic> j)=>PlannedItem(id:j['id'],type:TransactionType.values.firstWhere((e)=>e.name==j['type'],orElse:()=>TransactionType.expense),title:j['title'],category:j['category'],amount:(j['amount'] as num).toDouble(),date:DateTime.parse(j['date']),recurrenceId:j['recurrenceId'],installmentId:j['installmentId'],installmentNumber:(j['installmentNumber'] as num?)?.toInt(),installmentTotal:(j['installmentTotal'] as num?)?.toInt());
}

class BudgetItem {
  final String id; String category; double limit;
  BudgetItem({required this.id,required this.category,required this.limit});
  Map<String,dynamic> toJson()=>{'id':id,'category':category,'limit':limit};
  factory BudgetItem.fromJson(Map<String,dynamic> j)=>BudgetItem(id:j['id'],category:j['category'],limit:(j['limit'] as num).toDouble());
}

class GoalItem {
  final String id; String name; double target; double saved; DateTime deadline;
  GoalItem({required this.id,required this.name,required this.target,required this.saved,required this.deadline});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'target':target,'saved':saved,'deadline':deadline.toIso8601String()};
  factory GoalItem.fromJson(Map<String,dynamic> j)=>GoalItem(id:j['id'],name:j['name'],target:(j['target'] as num).toDouble(),saved:(j['saved'] as num).toDouble(),deadline:DateTime.parse(j['deadline']));
}

class ReserveItem {
  final String id; String name; double target; double saved; int months;
  ReserveItem({required this.id,required this.name,required this.target,required this.saved,required this.months});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'target':target,'saved':saved,'months':months};
  factory ReserveItem.fromJson(Map<String,dynamic> j)=>ReserveItem(id:j['id'],name:j['name'],target:(j['target'] as num).toDouble(),saved:(j['saved'] as num).toDouble(),months:(j['months'] as num).toInt());
}

class InvestmentItem {
  final String id; String name; String assetClass; double amount; double estimatedReturn;
  InvestmentItem({required this.id,required this.name,required this.assetClass,required this.amount,required this.estimatedReturn});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'assetClass':assetClass,'amount':amount,'estimatedReturn':estimatedReturn};
  factory InvestmentItem.fromJson(Map<String,dynamic> j)=>InvestmentItem(id:j['id'],name:j['name'],assetClass:j['assetClass'],amount:(j['amount'] as num).toDouble(),estimatedReturn:(j['estimatedReturn'] as num).toDouble());
}

class RecurringRule {
  final String id; TransactionType type; String title; String category; double amount; String account; DateTime startDate; RecurrenceFrequency frequency; bool active;
  RecurringRule({required this.id,required this.type,required this.title,required this.category,required this.amount,required this.account,required this.startDate,required this.frequency,this.active=true});
  Map<String,dynamic> toJson()=>{'id':id,'type':type.name,'title':title,'category':category,'amount':amount,'account':account,'startDate':startDate.toIso8601String(),'frequency':frequency.name,'active':active};
  factory RecurringRule.fromJson(Map<String,dynamic> j)=>RecurringRule(id:j['id'],type:TransactionType.values.firstWhere((e)=>e.name==j['type'],orElse:()=>TransactionType.expense),title:j['title'],category:j['category'],amount:(j['amount'] as num).toDouble(),account:j['account'],startDate:DateTime.parse(j['startDate']),frequency:RecurrenceFrequency.values.firstWhere((e)=>e.name==j['frequency'],orElse:()=>RecurrenceFrequency.monthly),active:j['active']??true);
}

class InstallmentPlan {
  final String id; String title; String category; String account; double totalAmount; int installments; DateTime startDate;
  InstallmentPlan({required this.id,required this.title,required this.category,required this.account,required this.totalAmount,required this.installments,required this.startDate});
  double get installmentValue=>installments<=0?0:totalAmount/installments;
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'category':category,'account':account,'totalAmount':totalAmount,'installments':installments,'startDate':startDate.toIso8601String()};
  factory InstallmentPlan.fromJson(Map<String,dynamic> j)=>InstallmentPlan(id:j['id'],title:j['title'],category:j['category'],account:j['account'],totalAmount:(j['totalAmount'] as num).toDouble(),installments:(j['installments'] as num).toInt(),startDate:DateTime.parse(j['startDate']));
}

class FinanceData {
  bool darkMode; bool privacyMode; bool onboardingCompleted; String primaryGoal;
  final List<AccountItem> accounts; final List<CardItem> cards; final List<TransactionItem> transactions; final List<PlannedItem> planned; final List<BudgetItem> budgets; final List<GoalItem> goals; final List<ReserveItem> reserves; final List<InvestmentItem> investments; final List<RecurringRule> recurringRules; final List<InstallmentPlan> installmentPlans;
  FinanceData({required this.darkMode,required this.privacyMode,required this.onboardingCompleted,required this.primaryGoal,required this.accounts,required this.cards,required this.transactions,required this.planned,required this.budgets,required this.goals,required this.reserves,required this.investments,required this.recurringRules,required this.installmentPlans});
  Map<String,dynamic> toJson()=>{'darkMode':darkMode,'privacyMode':privacyMode,'onboardingCompleted':onboardingCompleted,'primaryGoal':primaryGoal,'accounts':accounts.map((e)=>e.toJson()).toList(),'cards':cards.map((e)=>e.toJson()).toList(),'transactions':transactions.map((e)=>e.toJson()).toList(),'planned':planned.map((e)=>e.toJson()).toList(),'budgets':budgets.map((e)=>e.toJson()).toList(),'goals':goals.map((e)=>e.toJson()).toList(),'reserves':reserves.map((e)=>e.toJson()).toList(),'investments':investments.map((e)=>e.toJson()).toList(),'recurringRules':recurringRules.map((e)=>e.toJson()).toList(),'installmentPlans':installmentPlans.map((e)=>e.toJson()).toList()};
  String encode()=>jsonEncode(toJson());
  factory FinanceData.fromJson(Map<String,dynamic> j)=>FinanceData(
    darkMode:j['darkMode']??true,privacyMode:j['privacyMode']??false,onboardingCompleted:j['onboardingCompleted']??false,primaryGoal:j['primaryGoal']??'Controlar gastos',
    accounts:((j['accounts'] as List?)??[]).map((e)=>AccountItem.fromJson(Map<String,dynamic>.from(e))).toList(),
    cards:((j['cards'] as List?)??[]).map((e)=>CardItem.fromJson(Map<String,dynamic>.from(e))).toList(),
    transactions:((j['transactions'] as List?)??[]).map((e)=>TransactionItem.fromJson(Map<String,dynamic>.from(e))).toList(),
    planned:((j['planned'] as List?)??[]).map((e)=>PlannedItem.fromJson(Map<String,dynamic>.from(e))).toList(),
    budgets:((j['budgets'] as List?)??[]).map((e)=>BudgetItem.fromJson(Map<String,dynamic>.from(e))).toList(),
    goals:((j['goals'] as List?)??[]).map((e)=>GoalItem.fromJson(Map<String,dynamic>.from(e))).toList(),
    reserves:((j['reserves'] as List?)??[]).map((e)=>ReserveItem.fromJson(Map<String,dynamic>.from(e))).toList(),
    investments:((j['investments'] as List?)??[]).map((e)=>InvestmentItem.fromJson(Map<String,dynamic>.from(e))).toList(),
    recurringRules:((j['recurringRules'] as List?)??[]).map((e)=>RecurringRule.fromJson(Map<String,dynamic>.from(e))).toList(),
    installmentPlans:((j['installmentPlans'] as List?)??[]).map((e)=>InstallmentPlan.fromJson(Map<String,dynamic>.from(e))).toList(),
  );
}
