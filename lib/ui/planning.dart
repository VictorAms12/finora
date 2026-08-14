import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'forms.dart';

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final expected = store.monthIncome + store.plannedReceivable;
    final projection =
        store.cashBalance + store.plannedReceivable - store.plannedPayable;

    return PageScaffold(
      eyebrow: 'PLANEJAMENTO',
      title: 'Planejar',
      actions: [
        IconButton(
          onPressed: () => showBudgetForm(context),
          icon: const Icon(Icons.add_rounded),
        ),
        const SizedBox(width: 5),
      ],
      child: Column(
        children: [
          const MonthSwitcher(),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Expanded(
                  child: _metric(
                    context,
                    'Previsto',
                    money(context, expected),
                    FinoraColors.income,
                  ),
                ),
                Expanded(
                  child: _metric(
                    context,
                    'A pagar',
                    money(context, store.plannedPayable),
                    FinoraColors.expense,
                  ),
                ),
                Expanded(
                  child: _metric(
                    context,
                    'Projeção',
                    money(context, projection),
                    FinoraColors.balance,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'ORÇAMENTOS', 'Limites por categoria'),
          const SizedBox(height: 7),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: store.data.budgets.isEmpty
                ? EmptyState(
                    icon: Icons.speed_rounded,
                    title: 'Planejamento ainda vazio',
                    subtitle:
                        'Defina limites para as categorias que mais importam.',
                    actionLabel: 'Criar orçamento',
                    onAction: () => showBudgetForm(context),
                  )
                : Column(
                    children: store.data.budgets
                        .map((item) => BudgetProgress(item: item))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'CALENDÁRIO', 'Lançamentos previstos'),
          const SizedBox(height: 7),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: store.selectedPlanned.isEmpty
                ? const EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'Nenhum compromisso neste mês',
                    subtitle:
                        'Parcelas e recorrências aparecerão automaticamente aqui.',
                  )
                : Column(
                    children: store.selectedPlanned
                        .map(
                          (item) => PlannedTile(
                            item: item,
                            onTap: () => showPlannedDetails(context, item),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'RECORRÊNCIAS', 'Contas automáticas'),
          const SizedBox(height: 7),
          SurfaceCard(
            child: store.data.recurringRules.isEmpty
                ? const EmptyState(
                    icon: Icons.repeat_rounded,
                    title: 'Sem recorrências',
                    subtitle:
                        'Marque um lançamento como semanal, mensal ou anual.',
                  )
                : Column(
                    children: store.data.recurringRules
                        .map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: FinoraColors.gold
                                    .withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.active
                                    ? Icons.repeat_rounded
                                    : Icons.pause_rounded,
                                color: item.active
                                    ? FinoraColors.goldBright
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 11.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${_frequency(item.frequency)} · ${item.category}',
                              style: const TextStyle(fontSize: 8.5),
                            ),
                            trailing: Text(
                              money(context, item.amount),
                              style: TextStyle(
                                fontSize: 10.3,
                                fontWeight: FontWeight.w900,
                                color:
                                    item.type == TransactionType.income
                                        ? FinoraColors.income
                                        : FinoraColors.expense,
                              ),
                            ),
                            onTap: () =>
                                showRecurringDetails(context, item),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'PARCELAMENTOS', 'Compras em andamento'),
          const SizedBox(height: 7),
          SurfaceCard(
            child: store.data.installmentPlans.isEmpty
                ? const EmptyState(
                    icon: Icons.credit_card_outlined,
                    title: 'Nenhum parcelamento',
                    subtitle:
                        'Ao parcelar uma despesa, as próximas parcelas entram no planejamento.',
                  )
                : Column(
                    children: store.data.installmentPlans
                        .map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: FinoraColors.expense
                                    .withValues(alpha: .09),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.credit_card_outlined,
                                color: FinoraColors.expense,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 11.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${store.paidInstallments(item.id)}/${item.installments} realizadas · ${money(context, item.installmentValue)}',
                              style: const TextStyle(fontSize: 8.5),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () =>
                                showInstallmentDetails(context, item),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _frequency(RecurrenceFrequency frequency) {
    if (frequency == RecurrenceFrequency.weekly) return 'Semanal';
    if (frequency == RecurrenceFrequency.yearly) return 'Anual';
    return 'Mensal';
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) =>
      Padding(
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
