import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final savingRate = store.monthIncome == 0
        ? 0
        : ((store.monthBalance / store.monthIncome) * 100).round();
    final categories = store.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final previous = store.previousMonthExpense;
    final change = previous <= 0
        ? null
        : ((store.monthExpense - previous) / previous) * 100;
    final snapshot = store.snapshotForMonth(store.selectedMonth);

    double averageIncome(int months) {
      var total = 0.0;
      for (var i = 0; i < months; i++) {
        total += store.incomeForMonth(
          DateTime(
            store.selectedMonth.year,
            store.selectedMonth.month - i,
          ),
        );
      }
      return total / months;
    }

    double averageExpense(int months) {
      var total = 0.0;
      for (var i = 0; i < months; i++) {
        total += store.expenseForMonth(
          DateTime(
            store.selectedMonth.year,
            store.selectedMonth.month - i,
          ),
        );
      }
      return total / months;
    }

    final expenseBySource = <String, double>{};
    for (final tx in store.monthTransactions) {
      if (tx.type != TransactionType.expense) continue;
      final source = tx.paymentKind == PaymentKind.card
          ? 'Cartão · ${store.findCard(tx.cardId)?.name ?? tx.account}'
          : 'Conta · ${tx.account}';
      expenseBySource[source] = (expenseBySource[source] ?? 0) + tx.amount;
    }
    final sources = expenseBySource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final largestExpenses = store.monthTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    var monthlyRecurringExpense = 0.0;
    for (final rule in store.data.recurringRules.where(
      (rule) => rule.active && rule.type == TransactionType.expense,
    )) {
      monthlyRecurringExpense += switch (rule.frequency) {
        RecurrenceFrequency.weekly => rule.amount * 4.345,
        RecurrenceFrequency.monthly => rule.amount,
        RecurrenceFrequency.yearly => rule.amount / 12,
      };
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const MonthSwitcher(),
          const SizedBox(height: 10),
          if (store.selectedIsFuture)
            SurfaceCard(
              borderColor: FinoraColors.balance.withValues(alpha: .28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROJEÇÃO DO MÊS', style: eyebrowStyle(context)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          context,
                          'Saldo inicial',
                          money(context, store.selectedCashProjectedOpening),
                          FinoraColors.balance,
                        ),
                      ),
                      Expanded(
                        child: _metric(
                          context,
                          'A receber',
                          money(context, store.selectedCashPlannedReceivable),
                          FinoraColors.income,
                        ),
                      ),
                      Expanded(
                        child: _metric(
                          context,
                          'A pagar',
                          money(context, store.selectedCashPlannedPayable),
                          FinoraColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Saldo final projetado',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        money(context, store.selectedCashProjectedClosing),
                        style: const TextStyle(
                          color: FinoraColors.balance,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else ...[
            if (store.selectedIsPast && snapshot != null)
              SurfaceCard(
                borderColor: FinoraColors.gold.withValues(alpha: .25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FECHAMENTO MENSAL', style: eyebrowStyle(context)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _metric(
                            context,
                            'Saldo inicial',
                            money(context, snapshot.openingBalance),
                            FinoraColors.balance,
                          ),
                        ),
                        Expanded(
                          child: _metric(
                            context,
                            'Saldo final',
                            money(context, snapshot.closingBalance),
                            FinoraColors.goldBright,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (store.selectedIsPast && snapshot != null)
              const SizedBox(height: 10),
            SurfaceCard(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Expanded(
                    child: _metric(
                      context,
                      'Economia',
                      '$savingRate%',
                      FinoraColors.income,
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      context,
                      'Entradas',
                      money(context, store.monthIncome),
                      FinoraColors.income,
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      context,
                      'Saídas',
                      money(context, store.monthExpense),
                      FinoraColors.expense,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (!store.selectedIsFuture)
            SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (change != null && change > 0
                              ? FinoraColors.expense
                              : FinoraColors.income)
                          .withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      change == null
                          ? Icons.horizontal_rule_rounded
                          : change > 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                      color: change != null && change > 0
                          ? FinoraColors.expense
                          : FinoraColors.income,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comparação com o mês anterior',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          change == null
                              ? 'Sem dados suficientes para comparar.'
                              : '${change.abs().toStringAsFixed(1)}% ${change > 0 ? 'a mais' : 'a menos'} em despesas.',
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EVOLUÇÃO DE DESPESAS', style: eyebrowStyle(context)),
                const SizedBox(height: 8),
                ExpenseBars(values: store.lastSixMonthExpenses),
              ],
            ),
          ),
          if (!store.selectedIsFuture) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MÉDIAS DO HISTÓRICO', style: eyebrowStyle(context)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          context,
                          'Gasto médio · 3m',
                          money(context, averageExpense(3)),
                          FinoraColors.expense,
                        ),
                      ),
                      Expanded(
                        child: _metric(
                          context,
                          'Gasto médio · 6m',
                          money(context, averageExpense(6)),
                          FinoraColors.warning,
                        ),
                      ),
                      Expanded(
                        child: _metric(
                          context,
                          'Receita média · 6m',
                          money(context, averageIncome(6)),
                          FinoraColors.income,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Compromissos recorrentes equivalem a cerca de ${money(context, monthlyRecurringExpense)} por mês.',
                    style: TextStyle(
                      fontSize: 8.7,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (sources.isNotEmpty) ...[
              const SizedBox(height: 10),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GASTOS POR ORIGEM', style: eyebrowStyle(context)),
                    const SizedBox(height: 6),
                    ...sources.take(8).map(
                      (entry) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 9.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        trailing: Text(
                          money(context, entry.value),
                          style: const TextStyle(
                            color: FinoraColors.expense,
                            fontSize: 9.3,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (largestExpenses.isNotEmpty) ...[
              const SizedBox(height: 10),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MAIORES DESPESAS', style: eyebrowStyle(context)),
                    const SizedBox(height: 6),
                    ...largestExpenses.take(5).map(
                      (item) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          categoryIcon(item.category),
                          color: FinoraColors.expense,
                          size: 18,
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 9.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          '${item.category} · ${shortDate(item.date)}',
                          style: const TextStyle(fontSize: 8.1),
                        ),
                        trailing: Text(
                          money(context, item.amount),
                          style: const TextStyle(
                            color: FinoraColors.expense,
                            fontSize: 9.3,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 10),
          SurfaceCard(
            child: categories.isEmpty
                ? const EmptyState(
                    icon: Icons.bar_chart_rounded,
                    title: 'Ainda sem dados suficientes',
                    subtitle:
                        'Os relatórios por categoria aparecem conforme os lançamentos são registrados.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GASTOS POR CATEGORIA', style: eyebrowStyle(context)),
                      const SizedBox(height: 8),
                      ...categories.map((entry) {
                        final ratio = store.monthExpense <= 0
                            ? 0.0
                            : entry.value / store.monthExpense;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    categoryIcon(entry.key),
                                    size: 17,
                                    color: FinoraColors.expense,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 10.8),
                                    ),
                                  ),
                                  Text(
                                    '${(ratio * 100).round()}% · ${money(context, entry.value)}',
                                    style: const TextStyle(
                                      color: FinoraColors.expense,
                                      fontSize: 9.2,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0).toDouble(),
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(20),
                                color: FinoraColors.expense,
                                backgroundColor: Theme.of(context).dividerColor,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) =>
      Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10.4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
}
