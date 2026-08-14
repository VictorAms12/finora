import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'forms.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
        actions: [
          IconButton(
            onPressed: () => showGoalForm(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: store.data.goals.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.track_changes_rounded,
                title: 'Nenhuma meta criada',
                subtitle: 'Crie um objetivo e acompanhe seu progresso.',
                actionLabel: 'Nova meta',
                onAction: () => showGoalForm(context),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: store.data.goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (_, index) {
                final goal = store.data.goals[index];
                final ratio = goal.target <= 0
                    ? 0.0
                    : (goal.saved / goal.target).clamp(0.0, 1.0).toDouble();
                final remaining = (goal.target - goal.saved)
                    .clamp(0.0, double.infinity)
                    .toDouble();
                final now = DateTime.now();
                final months = ((goal.deadline.year - now.year) * 12 +
                        goal.deadline.month -
                        now.month)
                    .clamp(1, 1200);
                final monthly = remaining / months;

                return SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${(ratio * 100).round()}%',
                            style: const TextStyle(
                              color: FinoraColors.goal,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                showGoalForm(context, editing: goal);
                              } else if (value == 'delete') {
                                final ok = await confirmAction(
                                  context,
                                  'Excluir meta?',
                                  'O progresso salvo desta meta será removido.',
                                );
                                if (ok) store.deleteGoal(goal.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Editar')),
                              PopupMenuItem(value: 'delete', child: Text('Excluir')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        '${money(context, goal.saved)} / ${money(context, goal.target)}',
                        style: const TextStyle(
                          color: FinoraColors.goal,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(20),
                        color: FinoraColors.goal,
                        backgroundColor: Theme.of(context).dividerColor,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        remaining <= 0
                            ? 'Meta concluída.'
                            : 'Para atingir até ${shortDate(goal.deadline)}: cerca de ${money(context, monthly)}/mês.',
                        style: const TextStyle(fontSize: 9.2),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Falta ${money(context, remaining)}',
                              style: TextStyle(
                                fontSize: 8.8,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                showContribution(context, true, goal.id),
                            child: const Text('+ Aporte'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class ReservesScreen extends StatelessWidget {
  const ReservesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [
          IconButton(
            onPressed: () => showReserveForm(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: store.data.reserves.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.shield_outlined,
                title: 'Nenhuma reserva criada',
                subtitle: 'Separe sua proteção financeira das metas.',
                actionLabel: 'Criar reserva',
                onAction: () => showReserveForm(context),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: store.data.reserves.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (_, index) {
                final reserve = store.data.reserves[index];
                final ratio = reserve.target <= 0
                    ? 0.0
                    : (reserve.saved / reserve.target)
                        .clamp(0.0, 1.0)
                        .toDouble();
                final monthlyCost = reserve.months <= 0
                    ? 0.0
                    : reserve.target / reserve.months;
                final coverage = monthlyCost <= 0
                    ? 0.0
                    : reserve.saved / monthlyCost;

                return SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reserve.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                showReserveForm(context, editing: reserve);
                              } else if (value == 'delete') {
                                final ok = await confirmAction(
                                  context,
                                  'Excluir reserva?',
                                  'O valor salvo desta reserva será removido do acompanhamento.',
                                );
                                if (ok) store.deleteReserve(reserve.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Editar')),
                              PopupMenuItem(value: 'delete', child: Text('Excluir')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        '${money(context, reserve.saved)} / ${money(context, reserve.target)}',
                        style: const TextStyle(
                          color: FinoraColors.warning,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(20),
                        color: FinoraColors.warning,
                        backgroundColor: Theme.of(context).dividerColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cobertura estimada: ${coverage.toStringAsFixed(1)} de ${reserve.months} meses.',
                        style: TextStyle(
                          fontSize: 8.8,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Meta mensal de proteção: ${money(context, monthlyCost)}',
                              style: TextStyle(
                                fontSize: 8.5,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                showContribution(context, false, reserve.id),
                            child: const Text('+ Aporte'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investimentos'),
        actions: [
          IconButton(
            onPressed: () => showInvestmentForm(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: store.data.investments.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.show_chart_rounded,
                title: 'Carteira vazia',
                subtitle:
                    'Adicione seus investimentos para acompanhar o patrimônio.',
                actionLabel: 'Adicionar',
                onAction: () => showInvestmentForm(context),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL INVESTIDO', style: eyebrowStyle(context)),
                      const SizedBox(height: 6),
                      Text(
                        money(context, store.investmentBalance),
                        style: const TextStyle(
                          color: FinoraColors.investment,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SurfaceCard(
                  child: Column(
                    children: store.data.investments.map((item) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 11.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          '${item.assetClass} · ${item.estimatedReturn.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 8.6),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              money(context, item.amount),
                              style: const TextStyle(
                                color: FinoraColors.investment,
                                fontSize: 10.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  showInvestmentForm(
                                    context,
                                    editing: item,
                                  );
                                } else if (value == 'delete') {
                                  final ok = await confirmAction(
                                    context,
                                    'Excluir investimento?',
                                    'O ativo será removido da carteira.',
                                  );
                                  if (ok) store.deleteInvestment(item.id);
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
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
