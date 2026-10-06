import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'forms.dart';
import 'reserve_forms.dart' as reserve_ui;

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
            tooltip: 'Nova meta',
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
                final rawMonths = (goal.deadline.year - now.year) * 12 +
                    goal.deadline.month -
                    now.month;
                final overdue = remaining > 0 &&
                    goal.deadline.isBefore(DateTime(now.year, now.month, now.day));
                final months = rawMonths.clamp(1, 1200);
                final monthly = remaining / months;
                final funding = store.fundingHistory(
                  FundingTargetType.goal,
                  goal.id,
                );

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
                            : overdue
                                ? 'Prazo encerrado em ${shortDate(goal.deadline)}. Edite a meta para definir um novo prazo.'
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
                          if (funding.isNotEmpty)
                            TextButton(
                              onPressed: () => _showFundingHistory(
                                context,
                                store,
                                FundingTargetType.goal,
                                goal.id,
                                goal.name,
                              ),
                              child: const Text('Histórico'),
                            ),
                          TextButton(
                            onPressed: () =>
                                showContribution(context, true, goal.id),
                            child: const Text('Movimentar'),
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
            tooltip: 'Criar reserva',
            onPressed: () => reserve_ui.showReserveEditor(context),
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
                onAction: () => reserve_ui.showReserveEditor(context),
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
                final referenceMonthlyCost = reserve.months <= 0
                    ? 0.0
                    : reserve.target / reserve.months;
                final coverage = referenceMonthlyCost <= 0
                    ? 0.0
                    : reserve.saved / referenceMonthlyCost;
                final remaining = (reserve.target - reserve.saved)
                    .clamp(0.0, double.infinity)
                    .toDouble();
                final excess = (reserve.saved - reserve.target)
                    .clamp(0.0, double.infinity)
                    .toDouble();
                final funding = store.fundingHistory(
                  FundingTargetType.reserve,
                  reserve.id,
                );

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
                          Text(
                            '${(ratio * 100).round()}%',
                            style: const TextStyle(
                              color: FinoraColors.warning,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                reserve_ui.showReserveEditor(
                                  context,
                                  editing: reserve,
                                );
                              } else if (value == 'delete') {
                                final ok = await confirmAction(
                                  context,
                                  'Excluir reserva?',
                                  'O valor salvo desta reserva será removido apenas do acompanhamento.',
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
                        'Cobertura estimada: ${coverage.toStringAsFixed(1)} meses · meta de ${reserve.months} meses.',
                        style: TextStyle(
                          fontSize: 8.8,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        excess > 0
                            ? 'Meta superada em ${money(context, excess)}.'
                            : remaining <= 0
                                ? 'Meta de proteção atingida.'
                                : 'Faltam ${money(context, remaining)} para a meta.',
                        style: TextStyle(
                          fontSize: 8.8,
                          fontWeight: FontWeight.w700,
                          color: excess > 0
                              ? FinoraColors.income
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Referência mensal: ${money(context, referenceMonthlyCost)}',
                              style: TextStyle(
                                fontSize: 8.5,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (funding.isNotEmpty)
                            TextButton(
                              onPressed: () => _showFundingHistory(
                                context,
                                store,
                                FundingTargetType.reserve,
                                reserve.id,
                                reserve.name,
                              ),
                              child: const Text('Histórico'),
                            ),
                          TextButton.icon(
                            onPressed: () => reserve_ui.showReserveMovement(
                              context,
                              reserve,
                            ),
                            icon: const Icon(Icons.swap_vert_rounded, size: 17),
                            label: const Text('Movimentar'),
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

Future<void> _showFundingHistory(
  BuildContext context,
  FinanceStore store,
  FundingTargetType type,
  String targetId,
  String title,
) async {
  final history = store.fundingHistory(type, targetId);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: history.isEmpty
            ? const Center(child: Text('Nenhuma movimentação vinculada.'))
            : ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    'Histórico · $title',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Somente aportes/retiradas que movimentaram uma conta aparecem aqui.',
                    style: TextStyle(
                      fontSize: 8.8,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...history.take(30).map(
                    (movement) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        movement.isContribution
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: movement.isContribution
                            ? FinoraColors.income
                            : FinoraColors.warning,
                      ),
                      title: Text(
                        movement.isContribution ? 'Aporte' : 'Retirada',
                        style: const TextStyle(
                          fontSize: 10.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        '${movement.accountName} · ${shortDate(movement.date)}',
                        style: const TextStyle(fontSize: 8.5),
                      ),
                      trailing: Text(
                        '${movement.isContribution ? '+' : '-'}${money(context, movement.amount.abs())}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
Future<void> _showInvestmentMovement(
  BuildContext context,
  InvestmentItem item,
) async {
  final store = context.read<FinanceStore>();
  final controller = TextEditingController();
  var adding = true;
  var accountName = '';

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text('Movimentar ${item.name}'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.add_rounded),
                    label: Text('Aportar'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.remove_rounded),
                    label: Text('Resgatar'),
                  ),
                ],
                selected: {adding},
                onSelectionChanged: (values) {
                  if (values.isNotEmpty) setLocal(() => adding = values.first);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: adding ? 'Valor do aporte' : 'Valor do resgate',
                  prefixText: 'R\$ ',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: accountName,
                decoration: const InputDecoration(
                  labelText: 'Movimentar saldo da conta',
                  helperText:
                      'Opcional. Vincular mantém o patrimônio consistente entre conta e investimento.',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Somente acompanhamento'),
                  ),
                  ...store.data.accounts.map(
                    (account) => DropdownMenuItem(
                      value: account.name,
                      child: Text(account.name),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setLocal(() => accountName = value ?? ''),
              ),
              if (item.hasPositionDetails) ...[
                const SizedBox(height: 9),
                Text(
                  'A movimentação ajusta valor atual e custo. Quantidade/preços podem ser refinados depois em Editar.',
                  style: TextStyle(
                    fontSize: 8.2,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = parseNumberInput(controller.text);
              if (value == null || value <= 0) {
                showFormError(context, 'Informe um valor maior que zero.');
                return;
              }
              final ok = store.moveInvestmentFunds(
                investmentId: item.id,
                value: value,
                withdraw: !adding,
                accountName: accountName,
              );
              if (!ok) {
                showFormError(
                  context,
                  adding
                      ? 'Não foi possível registrar o aporte.'
                      : 'O resgate não pode ser maior que o valor atual.',
                );
                return;
              }
              Navigator.pop(dialogContext);
              showSuccessFeedback(
                context,
                adding ? 'Aporte registrado.' : 'Resgate registrado.',
              );
            },
            child: Text(adding ? 'Aportar' : 'Resgatar'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
}

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final totalCurrent = store.investmentBalance;
    final totalCost = store.data.investments.fold<double>(
      0,
      (sum, item) => sum + item.investedAmount,
    );
    final totalResult = totalCurrent - totalCost;
    final totalPercent =
        totalCost <= 0 ? 0.0 : (totalResult / totalCost) * 100;
    final byClass = <String, double>{};
    for (final item in store.data.investments) {
      byClass[item.assetClass] = (byClass[item.assetClass] ?? 0) + item.amount;
    }
    final allocation = byClass.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investimentos'),
        actions: [
          IconButton(
            tooltip: 'Adicionar investimento',
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
                    'Adicione seus investimentos para acompanhar patrimônio, custo e resultado.',
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
                      Text('CARTEIRA', style: eyebrowStyle(context)),
                      const SizedBox(height: 6),
                      Text(
                        money(context, totalCurrent),
                        style: const TextStyle(
                          color: FinoraColors.investment,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _investmentMetric(
                              context,
                              'Custo',
                              money(context, totalCost),
                              Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: _investmentMetric(
                              context,
                              'Resultado',
                              '${totalResult >= 0 ? '+' : '-'}${money(context, totalResult.abs())}',
                              totalResult >= 0
                                  ? FinoraColors.income
                                  : FinoraColors.expense,
                            ),
                          ),
                          Expanded(
                            child: _investmentMetric(
                              context,
                              'Rentabilidade',
                              '${totalPercent >= 0 ? '+' : ''}${totalPercent.toStringAsFixed(1)}%',
                              totalResult >= 0
                                  ? FinoraColors.income
                                  : FinoraColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (allocation.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ALOCAÇÃO POR CLASSE', style: eyebrowStyle(context)),
                        const SizedBox(height: 9),
                        ...allocation.map((entry) {
                          final ratio = totalCurrent <= 0
                              ? 0.0
                              : (entry.value / totalCurrent)
                                  .clamp(0.0, 1.0)
                                  .toDouble();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 9.2,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(ratio * 100).round()}%',
                                      style: const TextStyle(
                                        fontSize: 8.8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 5,
                                  borderRadius: BorderRadius.circular(20),
                                  color: FinoraColors.investment,
                                  backgroundColor:
                                      Theme.of(context).dividerColor,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SurfaceCard(
                  child: Column(
                    children: store.data.investments.map((item) {
                      final history = store.fundingHistory(
                        FundingTargetType.investment,
                        item.id,
                      );
                      final resultColor = item.profitLoss >= 0
                          ? FinoraColors.income
                          : FinoraColors.expense;
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
                          item.hasPositionDetails
                              ? '${item.assetClass} · ${item.quantity.toStringAsFixed(4)} un. · PM ${money(context, item.averagePrice)}'
                              : '${item.assetClass} · custo ${money(context, item.investedAmount)}',
                          style: const TextStyle(fontSize: 8.6),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  money(context, item.amount),
                                  style: const TextStyle(
                                    color: FinoraColors.investment,
                                    fontSize: 10.4,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${item.profitLoss >= 0 ? '+' : ''}${item.profitLossPercent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: resultColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'move') {
                                  await _showInvestmentMovement(context, item);
                                } else if (value == 'history') {
                                  await _showFundingHistory(
                                    context,
                                    store,
                                    FundingTargetType.investment,
                                    item.id,
                                    item.name,
                                  );
                                } else if (value == 'edit') {
                                  await showInvestmentForm(
                                    context,
                                    editing: item,
                                  );
                                } else if (value == 'delete') {
                                  final ok = await confirmAction(
                                    context,
                                    'Excluir investimento?',
                                    'O ativo e o histórico de aportes vinculados serão removidos da carteira.',
                                  );
                                  if (ok) store.deleteInvestment(item.id);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'move',
                                  child: Text('Aportar / resgatar'),
                                ),
                                if (history.isNotEmpty)
                                  const PopupMenuItem(
                                    value: 'history',
                                    child: Text('Histórico'),
                                  ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                const PopupMenuItem(
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

  Widget _investmentMetric(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 9.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
}
