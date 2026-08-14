import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem item; final VoidCallback? onTap;
  const TransactionTile({super.key, required this.item, this.onTap});
  @override Widget build(BuildContext c) {
    final income=item.type==TransactionType.income, expense=item.type==TransactionType.expense;
    final color=income?FinoraColors.income:expense?FinoraColors.expense:FinoraColors.balance;
    final icon=income?Icons.south_west_rounded:expense?(item.paymentKind==PaymentKind.card?Icons.credit_card_rounded:Icons.north_east_rounded):Icons.swap_horiz_rounded;
    final prefix=income?'+ ':expense?'− ':'';
    return InkWell(onTap:onTap,borderRadius:BorderRadius.circular(14),child:Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Row(children:[Container(width:37,height:37,decoration:BoxDecoration(color:color.withValues(alpha:.09),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:color,size:18)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.title,style:const TextStyle(fontSize:11.3,fontWeight:FontWeight.w800)),Text('${item.category} · ${shortDate(item.date)} · ${item.account}',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:8.5,color:Theme.of(c).colorScheme.onSurfaceVariant))])),Text('$prefix${money(c,item.amount)}',style:TextStyle(fontSize:10.5,color:color,fontWeight:FontWeight.w900))])));
  }
}

class PlannedTile extends StatelessWidget {
  final PlannedItem item; final VoidCallback? onTap;
  const PlannedTile({super.key, required this.item, this.onTap});
  @override Widget build(BuildContext c) {
    final income=item.type==TransactionType.income, color=income?FinoraColors.income:FinoraColors.expense;
    return InkWell(onTap:onTap,borderRadius:BorderRadius.circular(14),child:Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[Container(width:37,height:37,alignment:Alignment.center,decoration:BoxDecoration(color:color.withValues(alpha:.09),borderRadius:BorderRadius.circular(12)),child:Text(item.date.day.toString().padLeft(2,'0'),style:TextStyle(color:color,fontWeight:FontWeight.w900))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.title,style:const TextStyle(fontSize:11.2,fontWeight:FontWeight.w800)),Text('${item.category} · ${shortDate(item.date)}',style:TextStyle(fontSize:8.5,color:Theme.of(c).colorScheme.onSurfaceVariant))])),Text('${income?'+':'−'} ${money(c,item.amount)}',style:TextStyle(color:color,fontSize:10.3,fontWeight:FontWeight.w900))])));
  }
}

class ExpenseBars extends StatelessWidget {
  final List<double> values; const ExpenseBars({super.key,required this.values});
  @override Widget build(BuildContext c){final max=values.fold<double>(1,(m,v)=>v>m?v:m),s=c.watch<FinanceStore>();return SizedBox(height:90,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:List.generate(values.length,(i){final d=DateTime(s.selectedMonth.year,s.selectedMonth.month-(values.length-1-i)),h=18+(values[i]/max)*48;return Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.end,children:[AnimatedContainer(duration:const Duration(milliseconds:260),height:h,width:18,decoration:BoxDecoration(color:i==values.length-1?FinoraColors.goldBright:FinoraColors.gold.withValues(alpha:.32),borderRadius:BorderRadius.circular(8))),const SizedBox(height:6),Text(monthShort[d.month-1],style:TextStyle(fontSize:7.5,color:Theme.of(c).colorScheme.onSurfaceVariant))]));}))));}
}

class BudgetProgress extends StatelessWidget {
  final BudgetItem item; const BudgetProgress({super.key,required this.item});
  @override Widget build(BuildContext c){final s=c.watch<FinanceStore>(),used=s.expensesByCategory[item.category]??0,ratio=item.limit<=0?0.0:used/item.limit,over=ratio>1;return Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Column(children:[Row(children:[Expanded(child:Text(item.category,style:const TextStyle(fontSize:11.3,fontWeight:FontWeight.w800))),Text('${money(c,used)} / ${money(c,item.limit)}',style:TextStyle(fontSize:8.6,color:over?FinoraColors.expense:Theme.of(c).colorScheme.onSurfaceVariant))]),const SizedBox(height:6),LinearProgressIndicator(value:ratio.clamp(0.0,1.0).toDouble(),minHeight:5,borderRadius:BorderRadius.circular(20),color:over?FinoraColors.expense:FinoraColors.goldBright,backgroundColor:Theme.of(c).dividerColor)]));}
}
