import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';

const _months=['JAN','FEV','MAR','ABR','MAI','JUN','JUL','AGO','SET','OUT','NOV','DEZ'];
String shortDate(DateTime d)=>'${d.day.toString().padLeft(2,'0')} ${_months[d.month-1]}';
String formatMoney(double value){final neg=value<0;final p=value.abs().toStringAsFixed(2).split('.');final raw=p[0];final b=StringBuffer();for(var i=0;i<raw.length;i++){b.write(raw[i]);final r=raw.length-i-1;if(r>0&&r%3==0)b.write('.');}final x='R\$ ${b.toString()},${p[1]}';return neg?'-$x':x;}
String money(BuildContext c,double v)=>c.watch<FinanceStore>().data.privacyMode?'R\$ ••••••':formatMoney(v);
TextStyle eyebrow(BuildContext c)=>TextStyle(fontSize:8.5,letterSpacing:1.3,fontWeight:FontWeight.w800,color:Theme.of(c).colorScheme.onSurfaceVariant);

class SurfaceCard extends StatelessWidget{final Widget child;final EdgeInsets padding;final Color? borderColor;const SurfaceCard({super.key,required this.child,this.padding=const EdgeInsets.all(16),this.borderColor});@override Widget build(BuildContext c)=>Container(padding:padding,decoration:BoxDecoration(color:Theme.of(c).cardColor,borderRadius:BorderRadius.circular(19),border:Border.all(color:borderColor??Theme.of(c).dividerColor)),child:child);}
class EmptyState extends StatelessWidget{final IconData icon;final String title,subtitle;final String? action;final VoidCallback? onTap;const EmptyState({super.key,required this.icon,required this.title,required this.subtitle,this.action,this.onTap});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.symmetric(vertical:24,horizontal:10),child:Column(children:[Container(width:50,height:50,decoration:BoxDecoration(color:FinoraColors.gold.withValues(alpha: .10),borderRadius:BorderRadius.circular(16)),child:Icon(icon,color:FinoraColors.goldBright)),const SizedBox(height:12),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text(subtitle,textAlign:TextAlign.center,style:TextStyle(fontSize:10.3,height:1.45,color:Theme.of(c).colorScheme.onSurfaceVariant)),if(action!=null&&onTap!=null)...[const SizedBox(height:12),FilledButton.tonal(onPressed:onTap,child:Text(action!))]]));}
Widget section(BuildContext c,String e,String t)=>Align(alignment:Alignment.centerLeft,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e,style:eyebrow(c)),const SizedBox(height:2),Text(t,style:const TextStyle(fontSize:14.5,fontWeight:FontWeight.w900))]));
Widget compact(BuildContext c,String label,String value,Color color)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:Column(children:[Text(label,style:TextStyle(fontSize:8.2,color:Theme.of(c).colorScheme.onSurfaceVariant)),const SizedBox(height:4),Text(value,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:color,fontSize:10.4,fontWeight:FontWeight.w900))]));

class PageScaffold extends StatelessWidget{final String eyebrowText,title;final Widget child;final List<Widget>? actions;const PageScaffold({super.key,required this.eyebrowText,required this.title,required this.child,this.actions});@override Widget build(BuildContext c)=>CustomScrollView(slivers:[SliverAppBar(floating:true,snap:true,toolbarHeight:68,titleSpacing:18,title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(eyebrowText,style:eyebrow(c)),const SizedBox(height:2),Text(title,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900))]),actions:actions),SliverPadding(padding:const EdgeInsets.fromLTRB(14,4,14,108),sliver:SliverToBoxAdapter(child:child))]);}

class HomeShell extends StatefulWidget{const HomeShell({super.key});@override State<HomeShell> createState()=>_HomeShellState();}
class _HomeShellState extends State<HomeShell>{final pc=PageController();int index=0;@override void dispose(){pc.dispose();super.dispose();}void go(int x){setState(()=>index=x);pc.animateToPage(x,duration:const Duration(milliseconds:290),curve:Curves.easeOutCubic);}@override Widget build(BuildContext c){const pages=[DashboardScreen(),PlanningScreen(),SizedBox(),TransactionsScreen(),MoreScreen()];return Scaffold(body:SafeArea(child:PageView(controller:pc,physics:const NeverScrollableScrollPhysics(),children:pages)),floatingActionButton:FloatingActionButton(onPressed:()=>showQuickActions(c),backgroundColor:FinoraColors.goldBright,foregroundColor:Colors.black,elevation:4,child:const Icon(Icons.add_rounded,size:30)),floatingActionButtonLocation:FloatingActionButtonLocation.centerDocked,bottomNavigationBar:BottomAppBar(height:72,color:Theme.of(c).brightness==Brightness.dark?const Color(0xFF050505):Colors.white,surfaceTintColor:Colors.transparent,notchMargin:9,shape:const CircularNotchedRectangle(),padding:EdgeInsets.zero,child:Row(children:[nav(c,Icons.home_rounded,'Início',0),nav(c,Icons.calendar_month_rounded,'Planejar',1),const Expanded(child:SizedBox()),nav(c,Icons.swap_vert_rounded,'Movimentos',3),nav(c,Icons.grid_view_rounded,'Mais',4)])));}Widget nav(BuildContext c,IconData i,String label,int x){final a=index==x;final color=a?FinoraColors.goldBright:Theme.of(c).colorScheme.onSurfaceVariant;return Expanded(child:InkWell(onTap:()=>go(x),child:Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Column(mainAxisSize:MainAxisSize.min,children:[AnimatedScale(duration:const Duration(milliseconds:180),scale:a?1.08:1,child:Icon(i,size:22,color:color)),const SizedBox(height:3),Text(label,style:TextStyle(fontSize:10,color:color,fontWeight:a?FontWeight.w800:FontWeight.w500))]))));}}

class DashboardScreen extends StatelessWidget{const DashboardScreen({super.key});@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();final rate=s.monthIncome==0?0:((s.monthBalance/s.monthIncome)*100).round();final recent=s.data.transactions.toList()..sort((a,b)=>b.date.compareTo(a.date));return PageScaffold(eyebrowText:'VISÃO GERAL',title:'Início',actions:[IconButton(onPressed:()=>s.setPrivacyMode(!s.data.privacyMode),icon:Icon(s.data.privacyMode?Icons.visibility_off_rounded:Icons.visibility_rounded)),const SizedBox(width:5)],child:Column(children:[
  SurfaceCard(borderColor:FinoraColors.gold.withValues(alpha: .34),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('PATRIMÔNIO',style:eyebrow(c))),Text(s.data.primaryGoal.toUpperCase(),style:const TextStyle(fontSize:8,color:FinoraColors.goldBright,fontWeight:FontWeight.w900))]),const SizedBox(height:8),Text(money(c,s.netWorth),style:const TextStyle(fontSize:31,height:1,fontWeight:FontWeight.w900,letterSpacing:-1.1)),const SizedBox(height:16),Row(children:[Expanded(child:_mini(c,'Entradas',s.monthIncome,FinoraColors.income)),_vline(c),Expanded(child:_mini(c,'Saídas',s.monthExpense,FinoraColors.expense)),_vline(c),Expanded(child:_mini(c,'Saldo',s.monthBalance,FinoraColors.balance))])])),
  const SizedBox(height:10),SurfaceCard(padding:const EdgeInsets.all(14),child:Row(children:[Container(width:40,height:40,decoration:BoxDecoration(color:FinoraColors.income.withValues(alpha: .10),borderRadius:BorderRadius.circular(13)),child:const Icon(Icons.wallet_outlined,color:FinoraColors.income,size:20)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Disponível para gastar',style:TextStyle(fontSize:9.5,color:Theme.of(c).colorScheme.onSurfaceVariant)),const SizedBox(height:3),Text(money(c,s.availableToSpend),style:const TextStyle(fontSize:19,color:FinoraColors.income,fontWeight:FontWeight.w900))])),const Icon(Icons.chevron_right_rounded,color:FinoraColors.goldBright)])),
  const SizedBox(height:14),section(c,'ESTE MÊS','Visão rápida'),const SizedBox(height:7),SurfaceCard(padding:const EdgeInsets.all(13),child:Row(children:[Expanded(child:compact(c,'A receber',money(c,s.plannedReceivable),FinoraColors.income)),Expanded(child:compact(c,'A pagar',money(c,s.plannedPayable),FinoraColors.expense)),Expanded(child:compact(c,'Economia','$rate%',FinoraColors.balance))])),
  const SizedBox(height:14),section(c,'ORÇAMENTO','Limites por categoria'),const SizedBox(height:7),SurfaceCard(padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),child:s.data.budgets.isEmpty?EmptyState(icon:Icons.speed_rounded,title:'Nenhum orçamento definido',subtitle:'Crie limites por categoria para acompanhar o que ainda pode gastar.',action:'Criar orçamento',onTap:()=>showBudgetForm(c)):Column(children:s.data.budgets.take(4).map((e)=>BudgetProgress(item:e)).toList())),
  const SizedBox(height:14),section(c,'PRÓXIMOS','Compromissos'),const SizedBox(height:7),SurfaceCard(padding:const EdgeInsets.symmetric(horizontal:14,vertical:6),child:s.futurePlanned.isEmpty?const EmptyState(icon:Icons.event_available_outlined,title:'Nada previsto por enquanto',subtitle:'Parcelas, recorrências e contas futuras aparecerão aqui.'):Column(children:s.futurePlanned.take(3).map((e)=>PlannedTile(item:e)).toList())),
  const SizedBox(height:14),section(c,'MOVIMENTAÇÕES','Atividade recente'),const SizedBox(height:7),SurfaceCard(padding:const EdgeInsets.symmetric(horizontal:14,vertical:5),child:s.data.transactions.isEmpty?EmptyState(icon:Icons.swap_vert_rounded,title:'Comece com seu primeiro lançamento',subtitle:'Use o botão + para adicionar uma entrada ou uma despesa.',action:'Adicionar',onTap:()=>showQuickActions(c)):Column(children:recent.take(5).map((e)=>TransactionTile(item:e)).toList()))
]));}
  Widget _mini(BuildContext c,String l,double v,Color color)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(l,style:TextStyle(fontSize:8.3,color:Theme.of(c).colorScheme.onSurfaceVariant)),const SizedBox(height:3),Text(money(c,v),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:10.4,fontWeight:FontWeight.w900,color:color))]);
  Widget _vline(BuildContext c)=>Container(width:1,height:28,margin:const EdgeInsets.symmetric(horizontal:6),color:Theme.of(c).dividerColor);
}

class BudgetProgress extends StatelessWidget{final BudgetItem item;const BudgetProgress({super.key,required this.item});@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();final used=s.expensesByCategory[item.category]??0;final ratio=item.limit<=0?0.0:used/item.limit;final over=ratio>1;return Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Column(children:[Row(children:[Expanded(child:Text(item.category,style:const TextStyle(fontSize:11.3,fontWeight:FontWeight.w800))),Text('${money(c,used)} / ${money(c,item.limit)}',style:TextStyle(fontSize:8.6,color:over?FinoraColors.expense:Theme.of(c).colorScheme.onSurfaceVariant))]),const SizedBox(height:6),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:ratio.clamp(0.0,1.0).toDouble(),minHeight:5,color:over?FinoraColors.expense:FinoraColors.goldBright,backgroundColor:Theme.of(c).dividerColor))]));}}
class PlannedTile extends StatelessWidget{final PlannedItem item;const PlannedTile({super.key,required this.item});@override Widget build(BuildContext c){final inc=item.type==TransactionType.income;final color=inc?FinoraColors.income:FinoraColors.expense;return Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[Container(width:37,height:37,alignment:Alignment.center,decoration:BoxDecoration(color:color.withValues(alpha: .09),borderRadius:BorderRadius.circular(12)),child:Text(item.date.day.toString().padLeft(2,'0'),style:TextStyle(color:color,fontWeight:FontWeight.w900))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.title,style:const TextStyle(fontSize:11.2,fontWeight:FontWeight.w800)),Text('${item.category} · ${shortDate(item.date)}',style:TextStyle(fontSize:8.5,color:Theme.of(c).colorScheme.onSurfaceVariant))])),Text('${inc?'+':'−'} ${money(c,item.amount)}',style:TextStyle(color:color,fontSize:10.3,fontWeight:FontWeight.w900))]));}}
class TransactionTile extends StatelessWidget{final TransactionItem item;const TransactionTile({super.key,required this.item});@override Widget build(BuildContext c){Color color=FinoraColors.balance;IconData icon=Icons.swap_horiz_rounded;if(item.type==TransactionType.income){color=FinoraColors.income;icon=Icons.south_west_rounded;}else if(item.type==TransactionType.expense){color=FinoraColors.expense;icon=Icons.north_east_rounded;}final pre=item.type==TransactionType.income?'+ ':item.type==TransactionType.expense?'− ':'';return InkWell(onTap:()=>showTransactionDetails(c,item),borderRadius:BorderRadius.circular(14),child:Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Row(children:[Container(width:37,height:37,decoration:BoxDecoration(color:color.withValues(alpha: .09),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:color,size:18)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.title,style:const TextStyle(fontSize:11.3,fontWeight:FontWeight.w800)),const SizedBox(height:2),Text('${item.category} · ${shortDate(item.date)}',style:TextStyle(fontSize:8.5,color:Theme.of(c).colorScheme.onSurfaceVariant))])),Text('$pre${money(c,item.amount)}',style:TextStyle(fontSize:10.5,color:color,fontWeight:FontWeight.w900))])));}}

class PlanningScreen extends StatelessWidget{const PlanningScreen({super.key});@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();final expected=s.monthIncome+s.plannedReceivable;final projection=s.cashBalance+s.plannedReceivable-s.plannedPayable;return PageScaffold(eyebrowText:'PLANEJAMENTO',title:'Planejar',actions:[IconButton(onPressed:()=>showBudgetForm(c),icon:const Icon(Icons.add_rounded)),const SizedBox(width:5)],child:Column(children:[SurfaceCard(padding:const EdgeInsets.all(13),child:Row(children:[Expanded(child:compact(c,'Previsto',money(c,expected),FinoraColors.income)),Expanded(child:compact(c,'A pagar',money(c,s.plannedPayable),FinoraColors.expense)),Expanded(child:compact(c,'Projeção',money(c,projection),FinoraColors.balance))])),const SizedBox(height:14),section(c,'ORÇAMENTOS','Limites por categoria'),const SizedBox(height:7),SurfaceCard(padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),child:s.data.budgets.isEmpty?EmptyState(icon:Icons.speed_rounded,title:'Planejamento ainda vazio',subtitle:'Defina limites para as categorias que mais importam.',action:'Criar orçamento',onTap:()=>showBudgetForm(c)):Column(children:s.data.budgets.map((e)=>BudgetProgress(item:e)).toList())),const SizedBox(height:14),section(c,'CALENDÁRIO','Próximos lançamentos'),const SizedBox(height:7),SurfaceCard(padding:const EdgeInsets.symmetric(horizontal:14,vertical:6),child:s.futurePlanned.isEmpty?const EmptyState(icon:Icons.calendar_today_outlined,title:'Nenhum compromisso futuro',subtitle:'Parcelas e recorrências aparecerão automaticamente aqui.'):Column(children:s.futurePlanned.take(12).map((e)=>PlannedTile(item:e)).toList())),const SizedBox(height:14),section(c,'RECORRÊNCIAS','Contas automáticas'),const SizedBox(height:7),SurfaceCard(child:s.data.recurringRules.isEmpty?const EmptyState(icon:Icons.repeat_rounded,title:'Sem recorrências',subtitle:'Marque um lançamento como semanal, mensal ou anual.'):Column(children:s.data.recurringRules.map((e)=>ListTile(dense:true,contentPadding:EdgeInsets.zero,leading:const Icon(Icons.repeat_rounded,color:FinoraColors.goldBright),title:Text(e.title,style:const TextStyle(fontSize:11.3,fontWeight:FontWeight.w800)),subtitle:Text(_freq(e.frequency),style:const TextStyle(fontSize:8.5)),trailing:Text(money(c,e.amount),style:TextStyle(fontSize:10.3,fontWeight:FontWeight.w900,color:e.type==TransactionType.income?FinoraColors.income:FinoraColors.expense)))).toList())),const SizedBox(height:14),section(c,'PARCELAMENTOS','Compras em andamento'),const SizedBox(height:7),SurfaceCard(child:s.data.installmentPlans.isEmpty?const EmptyState(icon:Icons.credit_card_outlined,title:'Nenhum parcelamento',subtitle:'As parcelas futuras são criadas automaticamente no planejamento.'):Column(children:s.data.installmentPlans.map((e)=>ListTile(dense:true,contentPadding:EdgeInsets.zero,leading:const Icon(Icons.credit_card_outlined,color:FinoraColors.expense),title:Text(e.title,style:const TextStyle(fontSize:11.3,fontWeight:FontWeight.w800)),subtitle:Text('${e.installments}x de ${money(c,e.installmentValue)}',style:const TextStyle(fontSize:8.5)),trailing:Text(money(c,e.totalAmount),style:const TextStyle(fontSize:10.3,fontWeight:FontWeight.w900)))).toList()))]));}
String _freq(RecurrenceFrequency f){if(f==RecurrenceFrequency.weekly)return'Semanal';if(f==RecurrenceFrequency.yearly)return'Anual';return'Mensal';}}

class TransactionsScreen extends StatefulWidget{const TransactionsScreen({super.key});@override State<TransactionsScreen> createState()=>_TransactionsScreenState();}
class _TransactionsScreenState extends State<TransactionsScreen>{TransactionType? filter;String search='';@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();var list=s.data.transactions.toList()..sort((a,b)=>b.date.compareTo(a.date));if(filter!=null)list=list.where((e)=>e.type==filter).toList();if(search.trim().isNotEmpty){final q=search.toLowerCase();list=list.where((e)=>'${e.title} ${e.category} ${e.account}'.toLowerCase().contains(q)).toList();}return PageScaffold(eyebrowText:'HISTÓRICO',title:'Movimentações',child:Column(children:[TextField(onChanged:(v)=>setState(()=>search=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search_rounded),hintText:'Pesquisar...')),const SizedBox(height:10),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[_chip('Todas',filter==null,()=>setState(()=>filter=null)),_chip('Entradas',filter==TransactionType.income,()=>setState(()=>filter=TransactionType.income)),_chip('Saídas',filter==TransactionType.expense,()=>setState(()=>filter=TransactionType.expense)),_chip('Transferências',filter==TransactionType.transfer,()=>setState(()=>filter=TransactionType.transfer))])),const SizedBox(height:10),SurfaceCard(padding:const EdgeInsets.symmetric(horizontal:14,vertical:5),child:list.isEmpty?EmptyState(icon:Icons.receipt_long_outlined,title:'Nenhuma movimentação',subtitle:'Seus lançamentos aparecerão aqui em ordem cronológica.',action:'Adicionar',onTap:()=>showQuickActions(c)):Column(children:list.map((e)=>TransactionTile(item:e)).toList()))]));}Widget _chip(String l,bool s,VoidCallback tap)=>Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(label:Text(l),selected:s,onSelected:(_)=>tap()));}

class MoreScreen extends StatelessWidget{const MoreScreen({super.key});@override Widget build(BuildContext c)=>PageScaffold(eyebrowText:'ORGANIZAÇÃO',title:'Mais',child:SurfaceCard(padding:const EdgeInsets.symmetric(horizontal:6,vertical:4),child:Column(children:[_more(c,Icons.track_changes_rounded,'Metas','Objetivos e aportes',FinoraColors.goal,const GoalsScreen()),_more(c,Icons.shield_outlined,'Reservas','Proteção financeira',FinoraColors.warning,const ReservesScreen()),_more(c,Icons.show_chart_rounded,'Investimentos','Carteira e patrimônio',FinoraColors.investment,const InvestmentsScreen()),_more(c,Icons.bar_chart_rounded,'Relatórios','Indicadores e análises',FinoraColors.balance,const ReportsScreen()),_more(c,Icons.account_balance_wallet_outlined,'Contas e cartões','Saldos, limites e faturas',FinoraColors.goldBright,const AccountsScreen()),_more(c,Icons.lightbulb_outline_rounded,'Conselhos','Insights automáticos',FinoraColors.income,const InsightsScreen()),_more(c,Icons.settings_outlined,'Configurações','Tema, privacidade e dados',Colors.grey,const SettingsScreen())])));Widget _more(BuildContext c,IconData i,String t,String s,Color color,Widget page)=>ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:8,vertical:3),leading:Container(width:40,height:40,decoration:BoxDecoration(color:color.withValues(alpha: .10),borderRadius:BorderRadius.circular(13)),child:Icon(i,color:color,size:20)),title:Text(t,style:const TextStyle(fontSize:12.3,fontWeight:FontWeight.w900)),subtitle:Text(s,style:const TextStyle(fontSize:8.8)),trailing:const Icon(Icons.chevron_right_rounded),onTap:()=>Navigator.push(c,PremiumRoute(page:page)));}

class GoalsScreen extends StatelessWidget{const GoalsScreen({super.key});@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();return Scaffold(appBar:AppBar(title:const Text('Metas'),actions:[IconButton(onPressed:()=>showGoalForm(c),icon:const Icon(Icons.add_rounded))]),body:s.data.goals.isEmpty?Center(child:EmptyState(icon:Icons.track_changes_rounded,title:'Nenhuma meta criada',subtitle:'Crie um objetivo e acompanhe seu progresso.',action:'Nova meta',onTap:()=>showGoalForm(c))):ListView.separated(padding:const EdgeInsets.all(14),itemCount:s.data.goals.length,separatorBuilder:(_,__)=>const SizedBox(height:9),itemBuilder:(_,i){final g=s.data.goals[i];final r=g.target<=0?0.0:(g.saved/g.target).clamp(0.0,1.0).toDouble();return SurfaceCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(g.name,style:const TextStyle(fontWeight:FontWeight.w900))),Text('${(r*100).round()}%',style:const TextStyle(color:FinoraColors.goal,fontWeight:FontWeight.w900))]),const SizedBox(height:9),Text('${money(c,g.saved)} / ${money(c,g.target)}',style:const TextStyle(color:FinoraColors.goal,fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:9),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:r,minHeight:6,color:FinoraColors.goal,backgroundColor:Theme.of(c).dividerColor)),Row(children:[Expanded(child:Text('Prazo ${shortDate(g.deadline)}',style:TextStyle(fontSize:8.8,color:Theme.of(c).colorScheme.onSurfaceVariant))),TextButton(onPressed:()=>showContribution(c,true,g.id),child:const Text('+ Aporte'))])])) ;}));}}
class ReservesScreen extends StatelessWidget{const ReservesScreen({super.key});@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();return Scaffold(appBar:AppBar(title:const Text('Reservas'),actions:[IconButton(onPressed:()=>showReserveForm(c),icon:const Icon(Icons.add_rounded))]),body:s.data.reserves.isEmpty?Center(child:EmptyState(icon:Icons.shield_outlined,title:'Nenhuma reserva criada',subtitle:'Separe sua proteção financeira das metas de compra.',action:'Criar reserva',onTap:()=>showReserveForm(c))):ListView.separated(padding:const EdgeInsets.all(14),itemCount:s.data.reserves.length,separatorBuilder:(_,__)=>const SizedBox(height:9),itemBuilder:(_,i){final g=s.data.reserves[i];final r=g.target<=0?0.0:(g.saved/g.target).clamp(0.0,1.0).toDouble();return SurfaceCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(g.name,style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:9),Text('${money(c,g.saved)} / ${money(c,g.target)}',style:const TextStyle(color:FinoraColors.warning,fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:9),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:r,minHeight:6,color:FinoraColors.warning,backgroundColor:Theme.of(c).dividerColor)),Row(children:[Expanded(child:Text('${g.months} meses de proteção',style:TextStyle(fontSize:8.8,color:Theme.of(c).colorScheme.onSurfaceVariant))),TextButton(onPressed:()=>showContribution(c,false,g.id),child:const Text('+ Aporte'))])])) ;}));}}
class InvestmentsScreen extends StatelessWidget{const InvestmentsScreen({super.key});@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();return Scaffold(appBar:AppBar(title:const Text('Investimentos'),actions:[IconButton(onPressed:()=>showInvestmentForm(c),icon:const Icon(Icons.add_rounded))]),body:s.data.investments.isEmpty?Center(child:EmptyState(icon:Icons.show_chart_rounded,title:'Carteira vazia',subtitle:'Adicione seus investimentos manualmente.',action:'Adicionar',onTap:()=>showInvestmentForm(c))):ListView(padding:const EdgeInsets.all(14),children:[SurfaceCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('TOTAL INVESTIDO',style:eyebrow(c)),const SizedBox(height:6),Text(money(c,s.investmentBalance),style:const TextStyle(color:FinoraColors.investment,fontSize:23,fontWeight:FontWeight.w900))])),const SizedBox(height:10),SurfaceCard(child:Column(children:s.data.investments.map((e)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(e.name,style:const TextStyle(fontSize:11.4,fontWeight:FontWeight.w800)),subtitle:Text('${e.assetClass} · ${e.estimatedReturn.toStringAsFixed(1)}% estimado',style:const TextStyle(fontSize:8.6)),trailing:Text(money(c,e.amount),style:const TextStyle(color:FinoraColors.investment,fontSize:10.4,fontWeight:FontWeight.w900)))).toList()))]));}}
class ReportsScreen extends StatelessWidget{const ReportsScreen({super.key});@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();final rate=s.monthIncome==0?0:((s.monthBalance/s.monthIncome)*100).round();final cats=s.expensesByCategory.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));return Scaffold(appBar:AppBar(title:const Text('Relatórios')),body:ListView(padding:const EdgeInsets.all(14),children:[SurfaceCard(padding:const EdgeInsets.all(13),child:Row(children:[Expanded(child:compact(c,'Economia','$rate%',FinoraColors.income)),Expanded(child:compact(c,'Entradas',money(c,s.monthIncome),FinoraColors.income)),Expanded(child:compact(c,'Saídas',money(c,s.monthExpense),FinoraColors.expense))])),const SizedBox(height:10),SurfaceCard(child:cats.isEmpty?const EmptyState(icon:Icons.bar_chart_rounded,title:'Ainda sem dados suficientes',subtitle:'Os relatórios são preenchidos conforme você usa o app.'):Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('GASTOS POR CATEGORIA',style:eyebrow(c)),const SizedBox(height:7),...cats.map((e)=>ListTile(dense:true,contentPadding:EdgeInsets.zero,title:Text(e.key,style:const TextStyle(fontSize:11)),trailing:Text(money(c,e.value),style:const TextStyle(color:FinoraColors.expense,fontSize:10.4,fontWeight:FontWeight.w900))))]))]));}}
class AccountsScreen extends StatelessWidget{const AccountsScreen({super.key});@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();return Scaffold(appBar:AppBar(title:const Text('Contas e cartões'),actions:[PopupMenuButton<String>(icon:const Icon(Icons.add_rounded),onSelected:(v){if(v=='account'){showAccountForm(c);}else{showCardForm(c);}},itemBuilder:(_)=>const[PopupMenuItem(value:'account',child:Text('Nova conta')),PopupMenuItem(value:'card',child:Text('Novo cartão'))])]),body:ListView(padding:const EdgeInsets.all(14),children:[Text('CONTAS',style:eyebrow(c)),const SizedBox(height:7),if(s.data.accounts.isEmpty)EmptyState(icon:Icons.account_balance_wallet_outlined,title:'Nenhuma conta',subtitle:'Adicione onde seu dinheiro fica.',action:'Nova conta',onTap:()=>showAccountForm(c))else...s.data.accounts.map((a)=>Padding(padding:const EdgeInsets.only(bottom:8),child:SurfaceCard(padding:const EdgeInsets.all(14),child:Row(children:[const Icon(Icons.account_balance_wallet_outlined,color:FinoraColors.goldBright),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a.name,style:const TextStyle(fontSize:11.7,fontWeight:FontWeight.w900)),Text(a.type,style:const TextStyle(fontSize:8.5))])),Text(money(c,a.balance),style:const TextStyle(color:FinoraColors.balance,fontSize:10.7,fontWeight:FontWeight.w900))])))),const SizedBox(height:12),Text('CARTÕES',style:eyebrow(c)),const SizedBox(height:7),if(s.data.cards.isEmpty)EmptyState(icon:Icons.credit_card_outlined,title:'Nenhum cartão',subtitle:'Cadastre cartões para visualizar limite e fatura.',action:'Novo cartão',onTap:()=>showCardForm(c))else...s.data.cards.map((x)=>Padding(padding:const EdgeInsets.only(bottom:8),child:SurfaceCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(x.name,style:const TextStyle(fontWeight:FontWeight.w900))),Text(money(c,x.used),style:const TextStyle(color:FinoraColors.expense,fontWeight:FontWeight.w900))]),const SizedBox(height:8),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:x.limit<=0?0:(x.used/x.limit).clamp(0.0,1.0).toDouble(),minHeight:5,color:FinoraColors.expense,backgroundColor:Theme.of(c).dividerColor)),const SizedBox(height:7),Text('Limite ${money(c,x.limit)} · fecha ${x.closeDay} · vence ${x.dueDay}',style:TextStyle(fontSize:8.6,color:Theme.of(c).colorScheme.onSurfaceVariant))]))))]));}}
class InsightsScreen extends StatelessWidget{const InsightsScreen({super.key});@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();final rate=s.monthIncome==0?0:((s.monthBalance/s.monthIncome)*100).round();final cats=s.expensesByCategory.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));final items=[Insight(Icons.savings_outlined,'Economia',s.monthIncome==0?'Registre entradas para acompanhar sua taxa de economia.':'Sua taxa de economia está em aproximadamente $rate%.',FinoraColors.income),Insight(Icons.pie_chart_outline,'Maior gasto',cats.isEmpty?'Ainda não há despesas suficientes para identificar um padrão.':'${cats.first.key} é a categoria com maior gasto neste mês.',FinoraColors.expense),Insight(Icons.shield_outlined,'Reserva',s.data.reserves.isEmpty?'Considere criar uma reserva de emergência.':'Você possui ${money(c,s.reserveBalance)} em reservas.',FinoraColors.warning),Insight(Icons.repeat_rounded,'Compromissos','${s.data.recurringRules.length} recorrência(s) e ${s.data.installmentPlans.length} parcelamento(s).',FinoraColors.goldBright)];return Scaffold(appBar:AppBar(title:const Text('Conselhos')),body:ListView.separated(padding:const EdgeInsets.all(14),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final x=items[i];return SurfaceCard(child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:40,height:40,decoration:BoxDecoration(color:x.color.withValues(alpha: .10),borderRadius:BorderRadius.circular(13)),child:Icon(x.icon,color:x.color,size:20)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x.title,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(x.body,style:TextStyle(fontSize:9.8,height:1.45,color:Theme.of(c).colorScheme.onSurfaceVariant))]))]));}));}}
class Insight{final IconData icon;final String title,body;final Color color;Insight(this.icon,this.title,this.body,this.color);}
class SettingsScreen extends StatelessWidget{const SettingsScreen({super.key});@override Widget build(BuildContext c){final s=c.watch<FinanceStore>();return Scaffold(appBar:AppBar(title:const Text('Configurações')),body:ListView(padding:const EdgeInsets.all(14),children:[SurfaceCard(child:Column(children:[SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Tema OLED',style:TextStyle(fontSize:12,fontWeight:FontWeight.w900)),subtitle:const Text('Preto absoluto, cinzas e dourado',style:TextStyle(fontSize:8.8)),value:s.data.darkMode,onChanged:s.setDarkMode),const Divider(),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Ocultar valores',style:TextStyle(fontSize:12,fontWeight:FontWeight.w900)),subtitle:const Text('Protege os valores na tela',style:TextStyle(fontSize:8.8)),value:s.data.privacyMode,onChanged:s.setPrivacyMode)])),const SizedBox(height:10),SurfaceCard(child:Column(children:[ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.science_outlined,color:FinoraColors.investment),title:const Text('Carregar dados de demonstração',style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w900)),subtitle:const Text('Opcional, somente para testar',style:TextStyle(fontSize:8.6)),onTap:()=>confirmAction(c,'Carregar demonstração?','Os dados atuais serão substituídos por exemplos.',s.loadDemo)),const Divider(),ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.cleaning_services_outlined,color:FinoraColors.expense),title:const Text('Limpar todos os dados',style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w900)),subtitle:const Text('Volta ao estado limpo para uso real',style:TextStyle(fontSize:8.6)),onTap:()=>confirmAction(c,'Limpar tudo?','Movimentações, metas, contas e planejamentos serão apagados.',s.clearForRealUse))]))]));}}

Future<void> confirmAction(BuildContext c,String title,String body,VoidCallback action)async{final ok=await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:Text(title),content:Text(body),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Confirmar'))]))??false;if(ok)action();}

Future<void> showQuickActions(BuildContext c)async{await showModalBottomSheet(context:c,showDragHandle:true,isScrollControlled:true,builder:(sheet)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(14,0,14,18),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Adicionar',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:12),GridView.count(crossAxisCount:3,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),mainAxisSpacing:8,crossAxisSpacing:8,childAspectRatio:1.05,children:[_quick(sheet,Icons.north_east_rounded,'Despesa',FinoraColors.expense,(){Navigator.pop(sheet);showTransactionForm(c,TransactionType.expense);}),_quick(sheet,Icons.south_west_rounded,'Receita',FinoraColors.income,(){Navigator.pop(sheet);showTransactionForm(c,TransactionType.income);}),_quick(sheet,Icons.swap_horiz_rounded,'Transferir',FinoraColors.balance,(){Navigator.pop(sheet);showTransferForm(c);}),_quick(sheet,Icons.track_changes_rounded,'Meta',FinoraColors.goal,(){Navigator.pop(sheet);showGoalForm(c);}),_quick(sheet,Icons.shield_outlined,'Reserva',FinoraColors.warning,(){Navigator.pop(sheet);showReserveForm(c);}),_quick(sheet,Icons.show_chart_rounded,'Investir',FinoraColors.investment,(){Navigator.pop(sheet);showInvestmentForm(c);})])]))));}
Widget _quick(BuildContext c,IconData i,String l,Color color,VoidCallback tap)=>InkWell(onTap:tap,borderRadius:BorderRadius.circular(17),child:Container(decoration:BoxDecoration(border:Border.all(color:Theme.of(c).dividerColor),borderRadius:BorderRadius.circular(17)),padding:const EdgeInsets.all(11),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:36,height:36,decoration:BoxDecoration(color:color.withValues(alpha: .10),borderRadius:BorderRadius.circular(12)),child:Icon(i,color:color,size:19)),const SizedBox(height:7),Text(l,style:const TextStyle(fontSize:9.8,fontWeight:FontWeight.w800))])));

Future<void> showTransactionForm(BuildContext c,TransactionType type,{TransactionItem? editing})async{
  final s=c.read<FinanceStore>();if(s.data.accounts.isEmpty){await showAccountForm(c);if(s.data.accounts.isEmpty)return;}
  final title=TextEditingController(text:editing?.title??'');final amount=TextEditingController(text:editing==null?'':editing.amount.toStringAsFixed(2));final parcels=TextEditingController(text:'2');
  final categories=type==TransactionType.income?['Renda','Renda extra','Venda','Reembolso','Outros']:['Alimentação','Transporte','Moradia','Saúde','Lazer','Compras','Tecnologia','Pets','Outros'];
  var category=editing?.category??categories.first;if(!categories.contains(category))category=categories.last;var account=editing?.account??s.data.accounts.first.name;if(!s.data.accounts.any((e)=>e.name==account))account=s.data.accounts.first.name;var recurring=false,installment=false;var frequency=RecurrenceFrequency.monthly;
  await showModalBottomSheet(context:c,showDragHandle:true,isScrollControlled:true,builder:(sheet)=>Padding(padding:EdgeInsets.fromLTRB(14,0,14,MediaQuery.of(sheet).viewInsets.bottom+16),child:StatefulBuilder(builder:(ctx,setLocal)=>SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(editing!=null?'Editar movimentação':type==TransactionType.income?'Nova entrada':'Nova despesa',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:13),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:installment?'Valor total da compra':'Valor')),const SizedBox(height:9),TextField(controller:title,decoration:const InputDecoration(labelText:'Descrição')),const SizedBox(height:9),DropdownButtonFormField<String>(initialValue:category,decoration:const InputDecoration(labelText:'Categoria'),items:categories.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v){if(v!=null)setLocal(()=>category=v);}),const SizedBox(height:9),DropdownButtonFormField<String>(initialValue:account,decoration:const InputDecoration(labelText:'Conta'),items:s.data.accounts.map((e)=>DropdownMenuItem(value:e.name,child:Text(e.name))).toList(),onChanged:(v){if(v!=null)setLocal(()=>account=v);}),
  if(editing==null&&type==TransactionType.expense)...[const SizedBox(height:4),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Compra parcelada',style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w800)),subtitle:const Text('Gera automaticamente as próximas parcelas',style:TextStyle(fontSize:8.5)),value:installment,onChanged:(v)=>setLocal((){installment=v;if(v)recurring=false;})),if(installment)TextField(controller:parcels,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantidade de parcelas'))],
  if(editing==null&&!installment)...[SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Recorrente',style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w800)),subtitle:const Text('Programa as próximas ocorrências',style:TextStyle(fontSize:8.5)),value:recurring,onChanged:(v)=>setLocal(()=>recurring=v)),if(recurring)DropdownButtonFormField<RecurrenceFrequency>(initialValue:frequency,decoration:const InputDecoration(labelText:'Frequência'),items:const[DropdownMenuItem(value:RecurrenceFrequency.weekly,child:Text('Semanal')),DropdownMenuItem(value:RecurrenceFrequency.monthly,child:Text('Mensal')),DropdownMenuItem(value:RecurrenceFrequency.yearly,child:Text('Anual'))],onChanged:(v){if(v!=null)setLocal(()=>frequency=v);})],
  const SizedBox(height:13),SizedBox(width:double.infinity,child:FilledButton(onPressed:(){final v=double.tryParse(amount.text.replaceAll(',','.'))??0;if(v<=0||title.text.trim().isEmpty)return;if(editing!=null){s.updateTransaction(editing,TransactionItem(id:editing.id,type:editing.type,title:title.text.trim(),category:category,amount:v,date:editing.date,account:account,recurrenceId:editing.recurrenceId,installmentId:editing.installmentId,installmentNumber:editing.installmentNumber,installmentTotal:editing.installmentTotal));}else if(installment&&type==TransactionType.expense){final n=int.tryParse(parcels.text)??1;if(n<2)return;s.addInstallment(title.text.trim(),category,v,n,account);}else if(recurring){s.addRecurring(type,title.text.trim(),category,v,account,frequency);}else{s.addTransaction(TransactionItem(id:FinanceStore.id(),type:type,title:title.text.trim(),category:category,amount:v,date:DateTime.now(),account:account));}Navigator.pop(sheet);ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(editing==null?'Salvo com sucesso':'Movimentação atualizada'),behavior:SnackBarBehavior.floating));},child:Text(editing==null?'Salvar':'Atualizar')))])))));
}

Future<void> showTransactionDetails(
  BuildContext c,
  TransactionItem item,
) async {
  Color color = FinoraColors.balance;
  if (item.type == TransactionType.income) color = FinoraColors.income;
  if (item.type == TransactionType.expense) color = FinoraColors.expense;

  await showModalBottomSheet<void>(
    context: c,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              money(c, item.amount),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 14),
            _detail(c, 'Categoria', item.category),
            _detail(c, 'Conta', item.account),
            _detail(c, 'Data', shortDate(item.date)),
            if (item.installmentNumber != null)
              _detail(
                c,
                'Parcela',
                '${item.installmentNumber}/${item.installmentTotal}',
              ),
            if (item.recurrenceId != null)
              _detail(c, 'Tipo', 'Recorrente'),
            if (item.type != TransactionType.transfer) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheet);
                        showTransactionForm(
                          c,
                          item.type,
                          editing: item,
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                              context: c,
                              builder: (d) => AlertDialog(
                                title: const Text('Excluir movimentação?'),
                                content: const Text(
                                  'O saldo da conta será ajustado automaticamente.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(d, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(d, true),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (ok) {
                          c.read<FinanceStore>().deleteTransaction(item);
                          if (sheet.mounted) Navigator.pop(sheet);
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Excluir'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
Widget _detail(BuildContext c,String l,String v)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(l,style:TextStyle(fontSize:9.5,color:Theme.of(c).colorScheme.onSurfaceVariant))),Text(v,style:const TextStyle(fontSize:10.5,fontWeight:FontWeight.w800))]));

Future<void> showTransferForm(BuildContext c) async {
  final s = c.read<FinanceStore>();

  if (s.data.accounts.length < 2) {
    ScaffoldMessenger.of(c).showSnackBar(
      const SnackBar(
        content: Text('Cadastre pelo menos duas contas para transferir.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final amount = TextEditingController();
  var from = s.data.accounts.first.name;
  var to = s.data.accounts[1].name;

  await showModalBottomSheet<void>(
    context: c,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        MediaQuery.of(sheet).viewInsets.bottom + 16,
      ),
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Transferir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              initialValue: from,
              decoration: const InputDecoration(labelText: 'Origem'),
              items: s.data.accounts
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.name,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setLocal(() => from = v);
              },
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              initialValue: to,
              decoration: const InputDecoration(labelText: 'Destino'),
              items: s.data.accounts
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.name,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setLocal(() => to = v);
              },
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final v =
                      double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                  if (v <= 0 || from == to) return;

                  s.transfer(v, from, to);
                  Navigator.pop(sheet);
                },
                child: const Text('Transferir'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
class _F{final String label;final TextEditingController c;final bool number;_F(this.label,this.c,{this.number=false});}
Future<void> _simple(BuildContext c,String title,List<_F> fields,bool Function() save)async{await showModalBottomSheet(context:c,showDragHandle:true,isScrollControlled:true,builder:(sheet)=>Padding(padding:EdgeInsets.fromLTRB(14,0,14,MediaQuery.of(sheet).viewInsets.bottom+16),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:13),...fields.expand((f)=>[TextField(controller:f.c,keyboardType:f.number?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,decoration:InputDecoration(labelText:f.label)),const SizedBox(height:9)]),SizedBox(width:double.infinity,child:FilledButton(onPressed:(){if(save())Navigator.pop(sheet);},child:const Text('Salvar')))])));}
Future<void> showBudgetForm(BuildContext c)async{final a=TextEditingController(),b=TextEditingController();await _simple(c,'Novo orçamento',[_F('Categoria',a),_F('Limite mensal',b,number:true)],(){final v=double.tryParse(b.text.replaceAll(',','.'))??0;if(a.text.trim().isEmpty||v<=0)return false;c.read<FinanceStore>().addBudget(a.text.trim(),v);return true;});}
Future<void> showGoalForm(BuildContext c)async{final a=TextEditingController(),b=TextEditingController(),d=TextEditingController(text:'0');await _simple(c,'Nova meta',[_F('Nome',a),_F('Valor alvo',b,number:true),_F('Valor inicial',d,number:true)],(){final v=double.tryParse(b.text.replaceAll(',','.'))??0;final x=double.tryParse(d.text.replaceAll(',','.'))??0;if(a.text.trim().isEmpty||v<=0)return false;c.read<FinanceStore>().addGoal(a.text.trim(),v,x);return true;});}
Future<void> showReserveForm(BuildContext c)async{final a=TextEditingController(text:'Reserva de emergência'),b=TextEditingController(),d=TextEditingController(text:'0');await _simple(c,'Nova reserva',[_F('Nome',a),_F('Valor alvo',b,number:true),_F('Valor inicial',d,number:true)],(){final v=double.tryParse(b.text.replaceAll(',','.'))??0;final x=double.tryParse(d.text.replaceAll(',','.'))??0;if(v<=0)return false;c.read<FinanceStore>().addReserve(a.text.trim(),v,x);return true;});}
Future<void> showInvestmentForm(BuildContext c)async{final a=TextEditingController(),b=TextEditingController(),d=TextEditingController(text:'0');await _simple(c,'Novo investimento',[_F('Ativo / investimento',a),_F('Valor atual',b,number:true),_F('Rentabilidade estimada (%)',d,number:true)],(){final v=double.tryParse(b.text.replaceAll(',','.'))??0;final x=double.tryParse(d.text.replaceAll(',','.'))??0;if(a.text.trim().isEmpty||v<=0)return false;c.read<FinanceStore>().addInvestment(a.text.trim(),v,x);return true;});}
Future<void> showAccountForm(BuildContext c)async{final a=TextEditingController(),b=TextEditingController(text:'0');await _simple(c,'Nova conta',[_F('Nome da conta',a),_F('Saldo atual',b,number:true)],(){final v=double.tryParse(b.text.replaceAll(',','.'))??0;if(a.text.trim().isEmpty)return false;c.read<FinanceStore>().addAccount(a.text.trim(),v);return true;});}
Future<void> showCardForm(BuildContext c)async{final a=TextEditingController(),b=TextEditingController(),d=TextEditingController(text:'0');await _simple(c,'Novo cartão',[_F('Nome',a),_F('Limite',b,number:true),_F('Fatura atual',d,number:true)],(){final v=double.tryParse(b.text.replaceAll(',','.'))??0;final x=double.tryParse(d.text.replaceAll(',','.'))??0;if(a.text.trim().isEmpty||v<=0)return false;c.read<FinanceStore>().addCard(a.text.trim(),v,x);return true;});}
Future<void> showContribution(BuildContext c,bool goal,String id)async{final a=TextEditingController();await showDialog<void>(context:c,builder:(d)=>AlertDialog(title:const Text('Adicionar aporte'),content:TextField(controller:a,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Valor')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancelar')),FilledButton(onPressed:(){final v=double.tryParse(a.text.replaceAll(',','.'))??0;if(v<=0)return;if(goal){c.read<FinanceStore>().contributeGoal(id,v);}else{c.read<FinanceStore>().contributeReserve(id,v);}Navigator.pop(d);},child:const Text('Adicionar'))]));}
