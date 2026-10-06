import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'forms.dart';
import 'global_search.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final rate = store.monthIncome == 0
        ? 0
        : ((store.monthBalance / store.monthIncome) * 100).round();
    final recent = store.monthTransactions.take(5).toList();
    final snapshot = store.snapshotForMonth(store.selectedMonth);
    final previousIncome = store.incomeForMonth(store.previousSelectedMonth);
    final previousExpense = store.expenseForMonth(store.previousSelectedMonth);
    final expenseDelta = previousExpense <= 0
        ? null
        : ((store.monthExpense - previousExpense) / previousExpense) * 100;
    final incomeDelta = previousIncome <= 0
        ? null
        : ((store.monthIncome - previousIncome) / previousIncome) * 100;
    final trendExpenses = List<double>.generate(6, (index) {
      final month = DateTime(
        store.selectedMonth.year,
        store.selectedMonth.month - (5 - index),
      );
      return store.expenseForMonth(month);
    });
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final weekLimit = todayOnly.add(const Duration(days: 7));
    final upcomingWeek = store.data.planned
        .where(
          (item) =>
              item.status == PlannedStatus.planned &&
              !DateTime(item.date.year, item.date.month, item.date.day)
                  .isBefore(todayOnly) &&
              DateTime(item.date.year, item.date.month, item.date.day)
                  .isBefore(weekLimit),
        )
        .toList();
    final upcomingWeekTotal = upcomingWeek.fold<double>(
      0,
      (sum, item) =>
          item.type == TransactionType.income ? sum - item.amount : sum + item.amount,
    );

    final primaryLabel = store.selectedIsFuture
        ? 'SALDO PROJETADO'
        : store.selectedIsPast
        ? (snapshot == null ? 'RESULTADO DO MÊS' : 'FECHAMENTO DO MÊS')
        : 'PATRIMÔNIO';
    final primaryValue = store.selectedIsFuture
        ? store.selectedCashProjectedClosing
        : store.selectedIsPast
        ? (snapshot?.closingBalance ?? store.monthBalance)
        : store.netWorth;

    return PageScaffold(
      eyebrow: 'VISÃO GERAL',
      title: 'Início',
      actions: [
        IconButton(
          tooltip: 'Buscar',
          onPressed: () => Navigator.push(
            context,
            PremiumRoute(page: const GlobalSearchScreen()),
          ),
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Ocultar valores',
          onPressed: () => store.setPrivacyMode(!store.data.privacyMode),
          icon: Icon(
            store.data.privacyMode
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
        ),
        const SizedBox(width: 5),
      ],
      child: Column(
        children: [
          const MonthSwitcher(),
          if (store.selectedIsCurrent &&
              DateTime.now().day <= 3 &&
              (store.previousMonthExpense > 0 ||
                  store.incomeForMonth(store.previousSelectedMonth) > 0)) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              borderColor: FinoraColors.balance.withValues(alpha: .24),
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: FinoraColors.balance,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${monthLong[store.selectedMonth.month - 1]} começou',
                          style: const TextStyle(
                            fontSize: 10.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${monthLong[store.previousSelectedMonth.month - 1]} terminou com ${money(context, store.previousMonthExpense)} em gastos.',
                          style: TextStyle(
                            fontSize: 8.8,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: store.previousMonth,
                    child: Text(
                      'Ver ${monthShort[store.previousSelectedMonth.month - 1]}',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 230),
            child: SurfaceCard(
              key: ValueKey(
                '${store.selectedMonth.year}-${store.selectedMonth.month}',
              ),
              borderColor: FinoraColors.gold.withValues(alpha: .34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(primaryLabel, style: eyebrowStyle(context)),
                      ),
                      Text(
                        store.selectedIsFuture
                            ? 'PLANEJADO'
                            : store.selectedIsPast
                            ? 'HISTÓRICO'
                            : store.data.primaryGoal.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8,
                          color: FinoraColors.goldBright,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    money(context, primaryValue),
                    style: const TextStyle(
                      fontSize: 31,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (store.selectedIsFuture)
                    Row(
                      children: [
                        Expanded(
                          child: _mini(
                            context,
                            'Saldo inicial',
                            store.selectedCashProjectedOpening,
                            FinoraColors.balance,
                          ),
                        ),
                        _line(context),
                        Expanded(
                          child: _mini(
                            context,
                            'A receber',
                            store.selectedCashPlannedReceivable,
                            FinoraColors.income,
                          ),
                        ),
                        _line(context),
                        Expanded(
                          child: _mini(
                            context,
                            'A pagar',
                            store.selectedCashPlannedPayable,
                            FinoraColors.expense,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _mini(
                            context,
                            'Entradas · ${monthShort[store.selectedMonth.month - 1]}',
                            store.monthIncome,
                            FinoraColors.income,
                          ),
                        ),
                        _line(context),
                        Expanded(
                          child: _mini(
                            context,
                            'Saídas · ${monthShort[store.selectedMonth.month - 1]}',
                            store.monthExpense,
                            FinoraColors.expense,
                          ),
                        ),
                        _line(context),
                        Expanded(
                          child: _mini(
                            context,
                            'Resultado',
                            store.monthBalance,
                            FinoraColors.balance,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            onTap: () => showAvailableBreakdown(context),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        (store.selectedIsFuture
                                ? FinoraColors.balance
                                : store.selectedIsPast
                                ? FinoraColors.goldBright
                                : FinoraColors.income)
                            .withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    store.selectedIsFuture
                        ? Icons.query_stats_rounded
                        : store.selectedIsPast
                        ? Icons.history_rounded
                        : Icons.wallet_outlined,
                    color: store.selectedIsFuture
                        ? FinoraColors.balance
                        : store.selectedIsPast
                        ? FinoraColors.goldBright
                        : FinoraColors.income,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.selectedIsFuture
                            ? 'Saldo projetado para o fim do mês'
                            : store.selectedIsPast
                            ? (snapshot == null
                                  ? 'Resultado registrado no mês'
                                  : 'Detalhes do fechamento mensal')
                            : 'Disponível para gastar',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        money(
                          context,
                          store.selectedIsFuture
                              ? store.selectedCashProjectedClosing
                              : store.selectedIsPast
                              ? (snapshot?.closingBalance ?? store.monthBalance)
                              : store.availableToSpend,
                        ),
                        style: TextStyle(
                          fontSize: 19,
                          color: store.selectedIsFuture
                              ? FinoraColors.balance
                              : store.selectedIsPast
                              ? FinoraColors.goldBright
                              : FinoraColors.income,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: FinoraColors.goldBright,
                ),
              ],
            ),
          ),
          if (!store.selectedIsFuture) ...[
            const SizedBox(height: 14),
            sectionTitle(context, 'RITMO DO MÊS', 'Comparação e tendência recente'),
            const SizedBox(height: 7),
            SurfaceCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _comparisonMetric(
                          context,
                          'Entradas',
                          store.monthIncome,
                          incomeDelta,
                          positiveIsGood: true,
                        ),
                      ),
                      _line(context),
                      Expanded(
                        child: _comparisonMetric(
                          context,
                          'Saídas',
                          store.monthExpense,
                          expenseDelta,
                          positiveIsGood: false,
                        ),
                      ),
                      _line(context),
                      Expanded(
                        child: _mini(
                          context,
                          'Resultado',
                          store.monthBalance,
                          FinoraColors.balance,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'GASTOS DOS ÚLTIMOS 6 MESES',
                      style: eyebrowStyle(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TrendBars(values: trendExpenses),
                ],
              ),
            ),
          ],
          if (store.selectedIsCurrent && upcomingWeek.isNotEmpty) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const Icon(
                    Icons.upcoming_outlined,
                    color: FinoraColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Próximos 7 dias',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${upcomingWeek.length} compromisso(s) · impacto líquido de ${money(context, upcomingWeekTotal.abs())}',
                          style: TextStyle(
                            fontSize: 8.8,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (store.selectedIsCurrent && store.currentCashShortfall > 0) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              borderColor: FinoraColors.expense.withValues(alpha: .30),
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: FinoraColors.expense,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Faltam ${money(context, store.currentCashShortfall)} para cobrir os compromissos já previstos.',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (store.selectedIsCurrent && store.overduePlannedCount > 0) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              borderColor: FinoraColors.expense.withValues(alpha: .28),
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: FinoraColors.expense,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${store.overduePlannedCount} compromisso(s) previsto(s) estão atrasados.',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!store.selectedIsFuture && store.smartInsights.isNotEmpty) ...[
            const SizedBox(height: 14),
            sectionTitle(context, 'INSIGHTS', 'O que merece atenção'),
            const SizedBox(height: 7),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: store.smartInsights.take(3).map((insight) {
                  final color = switch (insight.severity) {
                    FinoraInsightSeverity.warning => FinoraColors.expense,
                    FinoraInsightSeverity.attention => FinoraColors.warning,
                    FinoraInsightSeverity.info => FinoraColors.balance,
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_graph_rounded, size: 18, color: color),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                insight.title,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                insight.message,
                                style: TextStyle(
                                  fontSize: 8.7,
                                  height: 1.35,
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
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          sectionTitle(context, 'ESTE PERÍODO', 'Visão rápida'),
          const SizedBox(height: 7),
          SurfaceCard(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Expanded(
                  child: _compact(
                    context,
                    'A receber',
                    money(context, store.selectedCashPlannedReceivable),
                    FinoraColors.income,
                  ),
                ),
                Expanded(
                  child: _compact(
                    context,
                    'A pagar',
                    money(context, store.selectedCashPlannedPayable),
                    FinoraColors.expense,
                  ),
                ),
                Expanded(
                  child: _compact(
                    context,
                    store.selectedIsFuture ? 'Projeção' : 'Economia',
                    store.selectedIsFuture
                        ? money(context, store.selectedCashProjectedClosing)
                        : '$rate%',
                    FinoraColors.balance,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'EVOLUÇÃO', 'Gastos dos últimos 6 meses'),
          const SizedBox(height: 7),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: ExpenseBars(values: store.lastSixMonthExpenses),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'ORÇAMENTO', 'Limites por categoria'),
          const SizedBox(height: 7),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: store.data.budgets.isEmpty
                ? EmptyState(
                    icon: Icons.speed_rounded,
                    title: 'Nenhum orçamento definido',
                    subtitle: 'Crie limites por categoria para acompanhar o que ainda pode gastar.',
                    actionLabel: 'Criar orçamento',
                    onAction: () => showBudgetForm(context),
                  )
                : Column(
                    children: store.data.budgets
                        .take(4)
                        .map((e) => BudgetProgress(item: e))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'PRÓXIMOS', 'Compromissos do período'),
          const SizedBox(height: 7),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: store.selectedPlanned.isEmpty
                ? EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'Nada previsto neste mês',
                    subtitle: 'Parcelas, recorrências e contas futuras aparecerão aqui.',
                    actionLabel: 'Adicionar previsto',
                    onAction: () => showPlannedForm(context),
                  )
                : Column(
                    children: store.selectedPlanned
                        .take(4)
                        .map(
                          (e) => PlannedTile(
                            item: e,
                            onTap: () => showPlannedDetails(context, e),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'MOVIMENTAÇÕES', 'Atividade do período'),
          const SizedBox(height: 7),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: recent.isEmpty
                ? EmptyState(
                    icon: Icons.swap_vert_rounded,
                    title: 'Sem movimentações neste mês',
                    subtitle:
                        'Use o botão + para adicionar uma receita ou despesa.',
                    actionLabel: 'Adicionar',
                    onAction: () => showQuickActions(context),
                  )
                : Column(
                    children: recent
                        .map(
                          (e) => TransactionTile(
                            item: e,
                            onTap: () => showTransactionDetails(context, e),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context) => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: Theme.of(context).dividerColor,
  );

  Widget _mini(BuildContext context, String label, double value, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8.3,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            money(context, value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.4,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      );

  Widget _compact(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
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
    ),
  );
}


Widget _comparisonMetric(
  BuildContext context,
  String label,
  double value,
  double? delta, {
  required bool positiveIsGood,
}) {
  final deltaValue = delta;
  final improving = deltaValue == null
      ? null
      : positiveIsGood
          ? deltaValue >= 0
          : deltaValue <= 0;
  final color = improving == null
      ? Theme.of(context).colorScheme.onSurfaceVariant
      : improving
          ? FinoraColors.income
          : FinoraColors.expense;
  final deltaText = deltaValue == null
      ? 'sem base anterior'
      : '${deltaValue >= 0 ? '+' : ''}${deltaValue.toStringAsFixed(0)}% vs mês anterior';

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
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
          money(context, value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          deltaText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 7.7,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _TrendBars extends StatelessWidget {
  final List<double> values;

  const _TrendBars({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );
    return SizedBox(
      height: 58,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < values.length; index++) ...[
            Expanded(
              child: Tooltip(
                message: money(context, values[index]),
                child: Container(
                  height: maxValue <= 0
                      ? 4
                      : 6 + (46 * (values[index] / maxValue)),
                  decoration: BoxDecoration(
                    color: index == values.length - 1
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .32),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            if (index != values.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
