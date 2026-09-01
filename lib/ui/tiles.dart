import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final store = context.read<FinanceStore>();
    final income = item.type == TransactionType.income;
    final expense = item.type == TransactionType.expense;
    final color = income
        ? FinoraColors.income
        : expense
        ? FinoraColors.expense
        : FinoraColors.balance;
    final icon = income
        ? Icons.south_west_rounded
        : expense
        ? (item.paymentKind == PaymentKind.card
              ? Icons.credit_card_rounded
              : Icons.north_east_rounded)
        : Icons.swap_horiz_rounded;
    final prefix = income
        ? '+ '
        : expense
        ? '− '
        : '';
    final extra = item.paymentKind == PaymentKind.card && expense
        ? ' · fatura ${monthShort[store.transactionInvoiceMonth(item).month - 1]}'
        : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 11.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${item.category} · ${shortDate(item.date)}$extra',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$prefix${money(context, item.amount)}',
              style: TextStyle(
                fontSize: 10.5,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlannedTile extends StatelessWidget {
  final PlannedItem item;
  final VoidCallback? onTap;

  const PlannedTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final income = item.type == TransactionType.income;
    final transfer = item.type == TransactionType.transfer;
    Color color;
    IconData icon;
    String state;

    if (item.status == PlannedStatus.settled) {
      color = FinoraColors.income;
      icon = Icons.check_rounded;
      state = 'realizado';
    } else if (item.status == PlannedStatus.skipped) {
      color = Colors.grey;
      icon = Icons.skip_next_rounded;
      state = 'ignorado';
    } else if (item.isOverdue) {
      color = FinoraColors.expense;
      icon = Icons.error_outline_rounded;
      state = 'atrasado';
    } else {
      color = transfer
          ? FinoraColors.balance
          : income
          ? FinoraColors.income
          : FinoraColors.warning;
      icon = transfer ? Icons.swap_horiz_rounded : Icons.schedule_rounded;
      state = 'previsto';
    }

    final prefix = transfer
        ? ''
        : income
        ? '+ '
        : '− ';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${item.category} · ${shortDate(item.date)} · $state',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$prefix${money(context, item.amount)}',
              style: TextStyle(
                color: color,
                fontSize: 10.3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseBars extends StatelessWidget {
  final List<double> values;

  const ExpenseBars({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    final max = values.fold<double>(1, (m, v) => v > m ? v : m);
    final selectedMonth = context.select<FinanceStore, DateTime>(
      (store) => store.selectedMonth,
    );
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final date = DateTime(
            selectedMonth.year,
            selectedMonth.month - (values.length - 1 - index),
          );
          final height = 18 + (values[index] / max) * 48;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  height: height,
                  width: 18,
                  decoration: BoxDecoration(
                    color: index == values.length - 1
                        ? FinoraColors.goldBright
                        : FinoraColors.gold.withValues(alpha: .32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  monthShort[date.month - 1],
                  style: TextStyle(
                    fontSize: 7.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class BudgetProgress extends StatelessWidget {
  final BudgetItem item;

  const BudgetProgress({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final used = store.expensesByCategory[item.category] ?? 0;
    final ratio = item.limit <= 0 ? 0.0 : used / item.limit;
    final over = ratio > 1;
    final remaining = (item.limit - used)
        .clamp(0.0, double.infinity)
        .toDouble();
    final now = DateTime.now();
    double? projected;
    if (store.selectedIsCurrent && now.day > 0 && used > 0) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      projected = used / now.day * daysInMonth;
    }
    final projectedOver = projected != null && projected > item.limit && !over;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 11.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${money(context, used)} / ${money(context, item.limit)}',
                style: TextStyle(
                  fontSize: 8.6,
                  color: over
                      ? FinoraColors.expense
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              over
                  ? '${(ratio * 100).round()}% usado · excedeu em ${money(context, used - item.limit)}'
                  : '${(ratio * 100).round()}% usado · ${money(context, remaining)} restantes',
              style: TextStyle(
                fontSize: 8.2,
                color: over
                    ? FinoraColors.expense
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (projectedOver) ...[
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ritmo atual: cerca de ${money(context, projected!)} até o fim do mês',
                style: const TextStyle(
                  fontSize: 8.2,
                  color: FinoraColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0).toDouble(),
            minHeight: 5,
            borderRadius: BorderRadius.circular(20),
            color: over ? FinoraColors.expense : FinoraColors.goldBright,
            backgroundColor: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }
}
