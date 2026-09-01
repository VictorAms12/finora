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
    final history = store.selectedPlannedHistory
        .where((e) => e.status != PlannedStatus.planned)
        .toList();

    return PageScaffold(
      eyebrow: 'PLANEJAMENTO',
      title: 'Planejar',
      actions: [
        IconButton(
          tooltip: 'Novo previsto',
          onPressed: () => showPlannedForm(context),
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
                    store.selectedIsPast ? 'Entradas' : 'A receber',
                    money(
                      context,
                      store.selectedIsPast
                          ? store.monthIncome
                          : store.selectedCashPlannedReceivable,
                    ),
                    FinoraColors.income,
                  ),
                ),
                Expanded(
                  child: _metric(
                    context,
                    store.selectedIsPast ? 'Saídas' : 'A pagar',
                    money(
                      context,
                      store.selectedIsPast
                          ? store.monthExpense
                          : store.selectedCashPlannedPayable,
                    ),
                    FinoraColors.expense,
                  ),
                ),
                Expanded(
                  child: _metric(
                    context,
                    store.selectedIsPast ? 'Resultado' : 'Saldo projetado',
                    money(
                      context,
                      store.selectedIsPast
                          ? store.monthBalance
                          : store.selectedCashProjectedClosing,
                    ),
                    FinoraColors.balance,
                  ),
                ),
              ],
            ),
          ),
          if (!store.selectedIsPast) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: FinoraColors.goldBright,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Projeção encadeada',
                          style: TextStyle(
                            fontSize: 10.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Inicia em ${money(context, store.selectedCashProjectedOpening)} e considera contas, parcelas, recorrências e faturas até o fim do mês.',
                          style: TextStyle(
                            fontSize: 8.8,
                            height: 1.4,
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
          ],
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
                    children: store.data.budgets.map((item) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: BudgetProgress(item: item)),
                          PopupMenuButton<String>(
                            iconSize: 18,
                            onSelected: (value) async {
                              if (value == 'edit') {
                                showBudgetForm(context, editing: item);
                              } else if (value == 'delete') {
                                final ok = await confirmAction(
                                  context,
                                  'Excluir orçamento?',
                                  'O limite de ${item.category} será removido.',
                                );
                                if (ok) store.deleteBudget(item.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 14),
          sectionTitle(context, 'CALENDÁRIO', 'Lançamentos previstos'),
          const SizedBox(height: 7),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: store.selectedPlanned.isEmpty
                ? EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'Nenhum compromisso pendente',
                    subtitle:
                        'Adicione um previsto ou use recorrências e parcelamentos.',
                    actionLabel: 'Novo previsto',
                    onAction: () => showPlannedForm(context),
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
          if (history.isNotEmpty) ...[
            const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text(
                'Histórico do planejamento',
                style: TextStyle(fontSize: 11.3, fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${history.length} item(ns) realizado(s) ou ignorado(s)',
                style: const TextStyle(fontSize: 8.5),
              ),
              children: [
                SurfaceCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    children: history
                        .map(
                          (item) => PlannedTile(
                            item: item,
                            onTap: () => showPlannedDetails(context, item),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
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
                    children: store.data.recurringRules.map((item) {
                      final duration = item.maxOccurrences != null
                          ? '${item.maxOccurrences}x'
                          : item.endDate != null
                              ? 'até ${shortDate(item.endDate!)}'
                              : 'contínua';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: FinoraColors.gold.withValues(alpha: .10),
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
                          '${recurrenceLabel(item.frequency)} · $duration · ${item.category}',
                          style: const TextStyle(fontSize: 8.5),
                        ),
                        trailing: Text(
                          money(context, item.amount),
                          style: TextStyle(
                            fontSize: 10.3,
                            fontWeight: FontWeight.w900,
                            color: item.type == TransactionType.income
                                ? FinoraColors.income
                                : FinoraColors.expense,
                          ),
                        ),
                        onTap: () => showRecurringDetails(context, item),
                      );
                    }).toList(),
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
                    children: store.data.installmentPlans.map((item) {
                      final paid = store.paidInstallments(item.id);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color:
                                FinoraColors.expense.withValues(alpha: .09),
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
                          '$paid/${item.installments} realizadas · ${money(context, item.installmentValue)}',
                          style: const TextStyle(fontSize: 8.5),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showInstallmentDetails(context, item),
                      );
                    }).toList(),
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
