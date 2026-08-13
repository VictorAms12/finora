import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class FinanceStore extends ChangeNotifier {
  static const _key='finora_data_v02';
  FinanceData data=emptyData();

  Future<void> load() async {
    final prefs=await SharedPreferences.getInstance();
    final raw=prefs.getString(_key);
    if(raw!=null){
      try{data=FinanceData.fromJson(jsonDecode(raw));}catch(_){data=emptyData();}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString(_key,data.encode());
  }
  void commit(){_save();notifyListeners();}
  static String id()=>DateTime.now().microsecondsSinceEpoch.toString();

  AccountItem? findAccount(String name){
    for(final a in data.accounts){if(a.name==name)return a;}
    return null;
  }

  void finishOnboarding(String account,double balance,String goal){
    data.onboardingCompleted=true;data.primaryGoal=goal;
    if(account.trim().isNotEmpty){data.accounts.add(AccountItem(id:id(),name:account.trim(),type:'Conta principal',balance:balance));}
    commit();
  }
  void setDarkMode(bool v){data.darkMode=v;commit();}
  void setPrivacyMode(bool v){data.privacyMode=v;commit();}
  bool sameMonth(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month;

  double get cashBalance=>data.accounts.fold<double>(0,(s,e)=>s+e.balance);
  double get reserveBalance=>data.reserves.fold<double>(0,(s,e)=>s+e.saved);
  double get investmentBalance=>data.investments.fold<double>(0,(s,e)=>s+e.amount);
  double get netWorth=>cashBalance+reserveBalance+investmentBalance;
  List<TransactionItem> get monthTransactions{final now=DateTime.now();return data.transactions.where((e)=>sameMonth(e.date,now)).toList();}
  double get monthIncome=>monthTransactions.where((e)=>e.type==TransactionType.income).fold<double>(0,(s,e)=>s+e.amount);
  double get monthExpense=>monthTransactions.where((e)=>e.type==TransactionType.expense).fold<double>(0,(s,e)=>s+e.amount);
  double get monthBalance=>monthIncome-monthExpense;

  List<PlannedItem> get futurePlanned{
    final n=DateTime.now();final today=DateTime(n.year,n.month,n.day);
    final list=data.planned.where((e)=>!e.date.isBefore(today)).toList();
    list.sort((a,b)=>a.date.compareTo(b.date));return list;
  }
  double get plannedReceivable=>futurePlanned.where((e)=>e.type==TransactionType.income).fold<double>(0,(s,e)=>s+e.amount);
  double get plannedPayable=>futurePlanned.where((e)=>e.type==TransactionType.expense).fold<double>(0,(s,e)=>s+e.amount);
  double get currentMonthPayable{final n=DateTime.now();return futurePlanned.where((e)=>e.type==TransactionType.expense&&sameMonth(e.date,n)).fold<double>(0,(s,e)=>s+e.amount);}
  double get budgetLimit=>data.budgets.fold<double>(0,(s,e)=>s+e.limit);
  double get availableToSpend{
    final goalPlan=data.goals.fold<double>(0,(s,g)=>s+(g.target-g.saved).clamp(0,200).toDouble());
    return (cashBalance-currentMonthPayable-goalPlan).clamp(0,double.infinity).toDouble();
  }
  Map<String,double> get expensesByCategory{
    final m=<String,double>{};
    for(final t in monthTransactions){if(t.type==TransactionType.expense)m[t.category]=(m[t.category]??0)+t.amount;}
    return m;
  }

  void addTransaction(TransactionItem item){
    data.transactions.add(item);final a=findAccount(item.account);
    if(a!=null){if(item.type==TransactionType.income)a.balance+=item.amount;if(item.type==TransactionType.expense)a.balance-=item.amount;}
    commit();
  }
  void updateTransaction(TransactionItem before,TransactionItem after){
    final i=data.transactions.indexWhere((e)=>e.id==before.id);if(i<0)return;
    final old=findAccount(before.account);if(old!=null){if(before.type==TransactionType.income)old.balance-=before.amount;if(before.type==TransactionType.expense)old.balance+=before.amount;}
    data.transactions[i]=after;final fresh=findAccount(after.account);if(fresh!=null){if(after.type==TransactionType.income)fresh.balance+=after.amount;if(after.type==TransactionType.expense)fresh.balance-=after.amount;}commit();
  }
  void deleteTransaction(TransactionItem item){
    final a=findAccount(item.account);if(a!=null){if(item.type==TransactionType.income)a.balance-=item.amount;if(item.type==TransactionType.expense)a.balance+=item.amount;}
    data.transactions.removeWhere((e)=>e.id==item.id);commit();
  }

  void addRecurring(TransactionType type,String title,String category,double amount,String account,RecurrenceFrequency frequency){
    final rid=id();final now=DateTime.now();
    data.recurringRules.add(RecurringRule(id:rid,type:type,title:title,category:category,amount:amount,account:account,startDate:now,frequency:frequency));
    data.transactions.add(TransactionItem(id:id(),type:type,title:title,category:category,amount:amount,date:now,account:account,recurrenceId:rid));
    final a=findAccount(account);if(a!=null){if(type==TransactionType.income)a.balance+=amount;if(type==TransactionType.expense)a.balance-=amount;}
    var cursor=now;for(var i=0;i<6;i++){cursor=nextOccurrence(cursor,frequency);data.planned.add(PlannedItem(id:id(),type:type,title:title,category:category,amount:amount,date:cursor,recurrenceId:rid));}
    commit();
  }

  void addInstallment(String title,String category,double total,int count,String account){
    final pid=id();final now=DateTime.now();final part=total/count;
    data.installmentPlans.add(InstallmentPlan(id:pid,title:title,category:category,account:account,totalAmount:total,installments:count,startDate:now));
    data.transactions.add(TransactionItem(id:id(),type:TransactionType.expense,title:'$title (1/$count)',category:category,amount:part,date:now,account:account,installmentId:pid,installmentNumber:1,installmentTotal:count));
    final a=findAccount(account);if(a!=null)a.balance-=part;
    for(var i=2;i<=count;i++){data.planned.add(PlannedItem(id:id(),type:TransactionType.expense,title:'$title ($i/$count)',category:category,amount:part,date:addMonths(now,i-1),installmentId:pid,installmentNumber:i,installmentTotal:count));}
    commit();
  }

  void transfer(double amount,String from,String to){
    final a=findAccount(from),b=findAccount(to);if(a!=null)a.balance-=amount;if(b!=null)b.balance+=amount;
    data.transactions.add(TransactionItem(id:id(),type:TransactionType.transfer,title:'Transferência',category:'Transferência',amount:amount,date:DateTime.now(),account:'$from → $to'));commit();
  }

  void addBudget(String category,double limit){data.budgets.add(BudgetItem(id:id(),category:category,limit:limit));commit();}
  void addGoal(String name,double target,double saved){data.goals.add(GoalItem(id:id(),name:name,target:target,saved:saved,deadline:DateTime.now().add(const Duration(days:365))));commit();}
  void addReserve(String name,double target,double saved){data.reserves.add(ReserveItem(id:id(),name:name,target:target,saved:saved,months:6));commit();}
  void addInvestment(String name,double amount,double ret){data.investments.add(InvestmentItem(id:id(),name:name,assetClass:'Renda fixa',amount:amount,estimatedReturn:ret));commit();}
  void addAccount(String name,double balance){data.accounts.add(AccountItem(id:id(),name:name,type:'Conta',balance:balance));commit();}
  void addCard(String name,double limit,double used){data.cards.add(CardItem(id:id(),name:name,limit:limit,used:used,closeDay:25,dueDay:5));commit();}
  void contributeGoal(String id,double value){final x=data.goals.firstWhere((e)=>e.id==id);x.saved=(x.saved+value).clamp(0,x.target).toDouble();commit();}
  void contributeReserve(String id,double value){final x=data.reserves.firstWhere((e)=>e.id==id);x.saved=(x.saved+value).clamp(0,x.target).toDouble();commit();}
  void loadDemo(){final dark=data.darkMode;data=demoData()..darkMode=dark;commit();}
  void clearForRealUse(){final dark=data.darkMode;data=emptyData()..darkMode=dark..onboardingCompleted=true;commit();}

  static DateTime nextOccurrence(DateTime d,RecurrenceFrequency f){if(f==RecurrenceFrequency.weekly)return d.add(const Duration(days:7));if(f==RecurrenceFrequency.yearly)return DateTime(d.year+1,d.month,d.day);return addMonths(d,1);}
  static DateTime addMonths(DateTime d,int months){final raw=d.month-1+months;final y=d.year+raw~/12;final m=raw%12+1;final last=DateTime(y,m+1,0).day;return DateTime(y,m,d.day>last?last:d.day);}

  static FinanceData emptyData()=>FinanceData(darkMode:true,privacyMode:false,onboardingCompleted:false,primaryGoal:'Controlar gastos',accounts:[],cards:[],transactions:[],planned:[],budgets:[],goals:[],reserves:[],investments:[],recurringRules:[],installmentPlans:[]);
  static FinanceData demoData(){final n=DateTime.now();return FinanceData(darkMode:true,privacyMode:false,onboardingCompleted:true,primaryGoal:'Planejar melhor',accounts:[AccountItem(id:'a1',name:'Conta principal',type:'Conta',balance:2400)],cards:[CardItem(id:'c1',name:'Cartão principal',limit:3000,used:620,closeDay:25,dueDay:5)],transactions:[TransactionItem(id:'t1',type:TransactionType.income,title:'Salário',category:'Renda',amount:1850,date:DateTime(n.year,n.month,5),account:'Conta principal'),TransactionItem(id:'t2',type:TransactionType.expense,title:'Mercado',category:'Alimentação',amount:176.40,date:DateTime(n.year,n.month,7),account:'Conta principal')],planned:[PlannedItem(id:'p1',type:TransactionType.expense,title:'Fatura do cartão',category:'Cartão',amount:620,date:DateTime(n.year,n.month+1,5))],budgets:[BudgetItem(id:'b1',category:'Alimentação',limit:500),BudgetItem(id:'b2',category:'Transporte',limit:300)],goals:[GoalItem(id:'g1',name:'Objetivo',target:2500,saved:600,deadline:n.add(const Duration(days:180)))],reserves:[ReserveItem(id:'r1',name:'Reserva de emergência',target:6000,saved:1400,months:4)],investments:[InvestmentItem(id:'i1',name:'Tesouro Selic',assetClass:'Renda fixa',amount:900,estimatedReturn:8.2)],recurringRules:[],installmentPlans:[]);}
}
