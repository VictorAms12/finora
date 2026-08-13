import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';

const _months = [
  'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
  'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'
];

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]}';

String _formatCurrency(double value) {
  final negative = value < 0;
  final abs = value.abs();
  final parts = abs.toStringAsFixed(2).split('.');
  final raw = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final posFromEnd = raw.length - i;
    buffer.write(raw[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
  }
  final result = 'R\$ ${buffer.toString()},${parts[1]}';
  return negative ? '-$result' : result;
}

String money(BuildContext context, double value) {
  final privacy = context.watch<FinanceStore>().data.privacyMode;
  return privacy ? 'R\$ ••••••' : _formatCurrency(value);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      DashboardScreen(),
      PlanningScreen(),
      SizedBox.shrink(),
      TransactionsScreen(),
      MoreScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        backgroundColor: FinoraColors.goldBright,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 72,
        notchMargin: 9,
        shape: const CircularNotchedRectangle(),
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _nav(Icons.home_rounded, 'Início', 0),
            _nav(Icons.calendar_month_rounded, 'Planejar', 1),
            const Expanded(child: SizedBox()),
            _nav(Icons.swap_vert_rounded, 'Movimentos', 3),
            _nav(Icons.grid_view_rounded, 'Mais', 4),
          ],
        ),
      ),
    );
  }

  Widget _nav(IconData icon, String label, int target) {
    final selected = index == target;
    final color = selected
        ? FinoraColors.goldBright
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => index = target),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PageScaffold extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const PageScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          toolbarHeight: 74,
          titleSpacing: 20,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: eyebrowStyle(context)),
              const SizedBox(height: 3),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          actions: actions,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}

TextStyle eyebrowStyle(BuildContext context) => TextStyle(
      fontSize: 9,
      letterSpacing: 1.3,
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border =
        dark ? const Color(0xFF242424) : const Color(0xFFE8E4DA);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? border),
      ),
      child: child,
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final savingRate = store.monthIncome == 0
        ? 0
        : ((store.monthBalance / store.monthIncome) * 100).round();

    return PageScaffold(
      eyebrow: 'VISÃO GERAL',
      title: 'Início',
      actions: [
        IconButton(
          onPressed: () =>
              store.setPrivacyMode(!store.data.privacyMode),
          icon: Icon(
            store.data.privacyMode
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(
        children: [
          SurfaceCard(
            borderColor: FinoraColors.gold.withOpacity(.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          Text('PATRIMÔNIO ATUAL', style: eyebrowStyle(context)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: FinoraColors.gold.withOpacity(.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'AGOSTO 2026',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: FinoraColors.goldBright,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  money(context, store.netWorth),
                  style: const TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                        child: _tinyMetric(
                            context, 'Contas', money(context, store.cashBalance))),
                    Expanded(
                        child: _tinyMetric(context, 'Reservas',
                            money(context, store.reserveBalance))),
                    Expanded(
                        child: _tinyMetric(context, 'Investimentos',
                            money(context, store.investmentBalance))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text('Disponível para gastar',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    Icon(Icons.circle, size: 11, color: FinoraColors.income),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  money(context, store.availableToSpend),
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: FinoraColors.income,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Compromissos previstos e aportes planejados já foram considerados.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.45,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              MetricCard(
                  label: 'Entradas',
                  value: money(context, store.monthIncome),
                  color: FinoraColors.income,
                  icon: Icons.south_west_rounded),
              MetricCard(
                  label: 'Saídas',
                  value: money(context, store.monthExpense),
                  color: FinoraColors.expense,
                  icon: Icons.north_east_rounded),
              MetricCard(
                  label: 'Saldo do mês',
                  value: money(context, store.monthBalance),
                  color: FinoraColors.balance,
                  icon: Icons.account_balance_wallet_outlined),
              MetricCard(
                  label: 'Contas previstas',
                  value: money(context, store.plannedPayable),
                  color: FinoraColors.warning,
                  icon: Icons.schedule_rounded),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'ORÇAMENTO', 'Por categoria'),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Column(
              children: store.data.budgets
                  .take(4)
                  .map((b) => BudgetProgress(budget: b))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'ATIVIDADE', 'Últimas movimentações'),
          const SizedBox(height: 8),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
            child: Column(
              children: (store.data.transactions.toList()
                    ..sort((a, b) => b.date.compareTo(a.date)))
                  .take(5)
                  .map((e) => TransactionTile(item: e))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            borderColor: FinoraColors.gold.withOpacity(.28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CENTRAL FINANCEIRA', style: eyebrowStyle(context)),
                const SizedBox(height: 4),
                const Text('Resumo do mês',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _centralMetric(
                        context,
                        'A receber',
                        money(context, store.plannedReceivable),
                        FinoraColors.income,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _centralMetric(
                        context,
                        'A pagar',
                        money(context, store.plannedPayable),
                        FinoraColors.expense,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _centralMetric(
                        context,
                        'Economia',
                        money(context, store.monthBalance),
                        FinoraColors.balance,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _centralMetric(
                        context,
                        'Taxa',
                        '$savingRate%',
                        FinoraColors.goal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _tinyMetric(BuildContext context, String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
        ),
      ],
    );

Widget _centralMetric(
        BuildContext context, String label, String value, Color color) =>
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );

Widget _sectionTitle(BuildContext context, String eyebrow, String title) =>
    Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: eyebrowStyle(context)),
          const SizedBox(height: 3),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );

class BudgetProgress extends StatelessWidget {
  final BudgetItem budget;

  const BudgetProgress({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final used = store.expensesByCategory[budget.category] ?? 0;
    final pct = budget.limit <= 0 ? 0.0 : used / budget.limit;
    final over = pct > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(budget.category,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              Text(
                '${money(context, used)} / ${money(context, budget.limit)}',
                style: TextStyle(
                  fontSize: 9.5,
                  color: over
                      ? FinoraColors.expense
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              color: over ? FinoraColors.expense : FinoraColors.goldBright,
              backgroundColor: Theme.of(context).dividerColor,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final TransactionItem item;

  const TransactionTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;

    switch (item.type) {
      case TransactionType.income:
        color = FinoraColors.income;
        icon = Icons.south_west_rounded;
      case TransactionType.expense:
        color = FinoraColors.expense;
        icon = Icons.north_east_rounded;
      case TransactionType.transfer:
        color = FinoraColors.balance;
        icon = Icons.swap_horiz_rounded;
    }

    final prefix = item.type == TransactionType.income
        ? '+ '
        : item.type == TransactionType.expense
            ? '− '
            : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  '${item.category} · ${_date(item.date)}',
                  style: TextStyle(
                    fontSize: 9.3,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$prefix${money(context, item.amount)}',
            style: TextStyle(
                fontSize: 11.2, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final expectedIncome = store.monthIncome + store.plannedReceivable;
    final savings = (expectedIncome - store.plannedBudgetLimit)
        .clamp(0.0, double.infinity)
        .toDouble();

    return PageScaffold(
      eyebrow: 'PLANEJAMENTO',
      title: 'Planejar',
      actions: [
        IconButton(
          onPressed: () => showBudgetForm(context),
          icon: const Icon(Icons.add_rounded),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              MetricCard(
                  label: 'Receita prevista',
                  value: money(context, expectedIncome),
                  color: FinoraColors.income,
                  icon: Icons.payments_outlined),
              MetricCard(
                  label: 'Limite de gastos',
                  value: money(context, store.plannedBudgetLimit),
                  color: FinoraColors.expense,
                  icon: Icons.speed_rounded),
              MetricCard(
                  label: 'Meta de economia',
                  value: money(context, savings),
                  color: FinoraColors.goal,
                  icon: Icons.savings_outlined),
              MetricCard(
                  label: 'Projeção final',
                  value: money(
                    context,
                    store.cashBalance +
                        store.plannedReceivable -
                        store.plannedPayable,
                  ),
                  color: FinoraColors.balance,
                  icon: Icons.timeline_rounded),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'ORÇAMENTOS', 'Limites por categoria'),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Column(
              children: store.data.budgets
                  .map((b) => BudgetProgress(budget: b))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'CALENDÁRIO', 'Próximos compromissos'),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Column(
              children: (store.data.planned.toList()
                    ..sort((a, b) => a.date.compareTo(b.date)))
                  .map((p) => _plannedTile(context, p))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plannedTile(BuildContext context, PlannedItem item) {
    final income = item.type == TransactionType.income;
    final color = income ? FinoraColors.income : FinoraColors.expense;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(.55),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              item.date.day.toString().padLeft(2, '0'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800)),
                Text(
                  '${item.category} · ${_date(item.date)}',
                  style: TextStyle(
                    fontSize: 9.3,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${income ? '+' : '−'} ${money(context, item.amount)}',
            style: TextStyle(
                fontSize: 11.2, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? filter;
  String search = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    var items = store.data.transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (filter != null) {
      items = items.where((e) => e.type == filter).toList();
    }
    if (search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      items = items
          .where((e) =>
              '${e.title} ${e.category} ${e.account}'
                  .toLowerCase()
                  .contains(q))
          .toList();
    }

    return PageScaffold(
      eyebrow: 'HISTÓRICO',
      title: 'Movimentações',
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Pesquisar movimentação...',
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todas', filter == null, () => setState(() => filter = null)),
                _filterChip('Entradas', filter == TransactionType.income,
                    () => setState(() => filter = TransactionType.income)),
                _filterChip('Saídas', filter == TransactionType.expense,
                    () => setState(() => filter = TransactionType.expense)),
                _filterChip('Transferências', filter == TransactionType.transfer,
                    () => setState(() => filter = TransactionType.transfer)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
            child: items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nenhuma movimentação encontrada.'),
                  )
                : Column(
                    children:
                        items.map((e) => TransactionTile(item: e)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      eyebrow: 'ORGANIZAÇÃO',
      title: 'Mais',
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            _more(context, Icons.track_changes_rounded, 'Metas',
                'Objetivos e aportes', FinoraColors.goal, const GoalsScreen()),
            _more(context, Icons.shield_outlined, 'Reservas',
                'Proteção e emergência', FinoraColors.warning, const ReservesScreen()),
            _more(context, Icons.show_chart_rounded, 'Investimentos',
                'Carteira e distribuição', FinoraColors.investment, const InvestmentsScreen()),
            _more(context, Icons.bar_chart_rounded, 'Relatórios',
                'Indicadores e saúde financeira', FinoraColors.balance, const ReportsScreen()),
            _more(context, Icons.account_balance_wallet_outlined, 'Contas e cartões',
                'Saldos, limites e faturas', FinoraColors.goldBright, const AccountsScreen()),
            _more(context, Icons.lightbulb_outline_rounded, 'Conselhos',
                'Insights dos seus dados', FinoraColors.income, const InsightsScreen()),
            _more(context, Icons.settings_outlined, 'Configurações',
                'Tema e privacidade', Colors.grey, const SettingsScreen()),
          ],
        ),
      ),
    );
  }

  Widget _more(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    Widget page,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 9.5)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}

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
              icon: const Icon(Icons.add_rounded))
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: store.data.goals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final goal = store.data.goals[i];
          final pct = goal.target <= 0
              ? 0.0
              : (goal.saved / goal.target).clamp(0.0, 1.0).toDouble();
          return SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(goal.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900))),
                    Text('${(pct * 100).round()}%',
                        style: const TextStyle(
                            color: FinoraColors.goal,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${money(context, goal.saved)} de ${money(context, goal.target)}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: FinoraColors.goal,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    color: FinoraColors.goal,
                    backgroundColor: Theme.of(context).dividerColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('Prazo ${_date(goal.deadline)}',
                          style: TextStyle(
                              fontSize: 9.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ),
                    TextButton(
                        onPressed: () =>
                            showContribution(context, true, goal.id),
                        child: const Text('+ Aporte')),
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
              icon: const Icon(Icons.add_rounded))
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: store.data.reserves.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final reserve = store.data.reserves[i];
          final pct = reserve.target <= 0
              ? 0.0
              : (reserve.saved / reserve.target).clamp(0.0, 1.0).toDouble();
          return SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reserve.name,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text(
                  '${money(context, reserve.saved)} de ${money(context, reserve.target)}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: FinoraColors.warning,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    color: FinoraColors.warning,
                    backgroundColor: Theme.of(context).dividerColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('${reserve.months} meses de proteção',
                          style: TextStyle(
                              fontSize: 9.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ),
                    TextButton(
                        onPressed: () =>
                            showContribution(context, false, reserve.id),
                        child: const Text('+ Aporte')),
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
    final total = store.investmentBalance;
    final classes = <String, double>{};

    for (final investment in store.data.investments) {
      classes[investment.assetClass] =
          (classes[investment.assetClass] ?? 0) + investment.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investimentos'),
        actions: [
          IconButton(
            onPressed: () => showInvestmentForm(context),
            icon: const Icon(Icons.add_rounded),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MetricCard(
            label: 'Total investido',
            value: money(context, total),
            color: FinoraColors.investment,
            icon: Icons.show_chart_rounded,
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DISTRIBUIÇÃO', style: eyebrowStyle(context)),
                const SizedBox(height: 10),
                ...classes.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(e.key,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ),
                        Text(
                          total <= 0
                              ? '0%'
                              : '${((e.value / total) * 100).round()}%',
                          style: const TextStyle(
                            color: FinoraColors.investment,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              children: store.data.investments
                  .map(
                    (i) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(i.name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                      subtitle: Text(
                        '${i.assetClass} · estimado ${i.estimatedReturn.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 9.3),
                      ),
                      trailing: Text(
                        money(context, i.amount),
                        style: const TextStyle(
                          color: FinoraColors.investment,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final savingRate = store.monthIncome == 0
        ? 0
        : ((store.monthBalance / store.monthIncome) * 100).round();
    final top = store.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final reserveTarget = store.data.reserves.fold<double>(
        0, (sum, reserve) => sum + reserve.target);
    final reservePct = reserveTarget <= 0
        ? 0.0
        : ((store.reserveBalance / reserveTarget) * 100)
            .clamp(0.0, 100.0)
            .toDouble();

    final score =
        (70 + savingRate * .35 + reservePct * .15).clamp(0.0, 100.0).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              MetricCard(
                  label: 'Taxa de economia',
                  value: '$savingRate%',
                  color: FinoraColors.income,
                  icon: Icons.savings_outlined),
              MetricCard(
                  label: 'Saúde financeira',
                  value: '$score/100',
                  color: FinoraColors.goal,
                  icon: Icons.favorite_outline_rounded),
              MetricCard(
                  label: 'Entradas',
                  value: money(context, store.monthIncome),
                  color: FinoraColors.income,
                  icon: Icons.south_west_rounded),
              MetricCard(
                  label: 'Saídas',
                  value: money(context, store.monthExpense),
                  color: FinoraColors.expense,
                  icon: Icons.north_east_rounded),
            ],
          ),
          const SizedBox(height: 14),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GASTOS POR CATEGORIA', style: eyebrowStyle(context)),
                const SizedBox(height: 8),
                ...top.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(e.key, style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      money(context, e.value),
                      style: const TextStyle(
                        fontSize: 11,
                        color: FinoraColors.expense,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas e cartões'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_rounded),
            onSelected: (value) {
              if (value == 'account') {
                showAccountForm(context);
              } else {
                showCardForm(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'account', child: Text('Nova conta')),
              PopupMenuItem(value: 'card', child: Text('Novo cartão')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('CONTAS', style: eyebrowStyle(context)),
          const SizedBox(height: 8),
          ...store.data.accounts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: FinoraColors.gold.withOpacity(.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: FinoraColors.goldBright,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900)),
                          Text(
                            a.type,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      money(context, a.balance),
                      style: const TextStyle(
                        color: FinoraColors.balance,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('CARTÕES', style: eyebrowStyle(context)),
          const SizedBox(height: 8),
          ...store.data.cards.map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(card.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900)),
                        ),
                        Text(
                          money(context, card.used),
                          style: const TextStyle(
                            color: FinoraColors.expense,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: card.limit <= 0
                            ? 0
                            : (card.used / card.limit)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                        minHeight: 6,
                        color: FinoraColors.expense,
                        backgroundColor: Theme.of(context).dividerColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Limite ${money(context, card.limit)} · fecha ${card.closeDay} · vence ${card.dueDay}',
                      style: TextStyle(
                        fontSize: 9.2,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final top = store.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final savingRate = store.monthIncome == 0
        ? 0
        : ((store.monthBalance / store.monthIncome) * 100).round();

    final insights = <InsightData>[
      InsightData(
        Icons.pie_chart_outline,
        'Maior concentração',
        top.isEmpty
            ? 'Ainda não há gastos suficientes para analisar.'
            : '${top.first.key} é a categoria que mais pesa nas despesas deste mês.',
        FinoraColors.expense,
      ),
      InsightData(
        Icons.savings_outlined,
        'Ritmo de economia',
        'Você está mantendo aproximadamente $savingRate% das entradas como saldo neste mês.',
        FinoraColors.income,
      ),
      InsightData(
        Icons.shield_outlined,
        'Reserva',
        'Sua reserva atual é de ${money(context, store.reserveBalance)}. Continue priorizando proteção antes de elevar gastos fixos.',
        FinoraColors.warning,
      ),
      InsightData(
        Icons.track_changes_rounded,
        'Metas',
        'Revise os aportes mensalmente para evitar que objetivos de longo prazo fiquem atrasados.',
        FinoraColors.goal,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Conselhos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final insight = insights[i];
          return SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: insight.color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(insight.icon, color: insight.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insight.title,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text(
                        insight.body,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.5,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InsightData {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  InsightData(this.icon, this.title, this.body, this.color);
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SurfaceCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tema OLED',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                  subtitle: const Text(
                    'Preto absoluto, cinzas e detalhes dourados',
                    style: TextStyle(fontSize: 9.5),
                  ),
                  value: store.data.darkMode,
                  onChanged: store.setDarkMode,
                  activeColor: FinoraColors.goldBright,
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ocultar valores',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                  subtitle: const Text('Modo de privacidade',
                      style: TextStyle(fontSize: 9.5)),
                  value: store.data.privacyMode,
                  onChanged: store.setPrivacyMode,
                  activeColor: FinoraColors.goldBright,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.restart_alt_rounded, color: FinoraColors.expense),
              title: const Text(
                'Restaurar dados de demonstração',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                'Apaga as alterações locais desta versão',
                style: TextStyle(fontSize: 9.5),
              ),
              onTap: () => _confirmReset(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Restaurar dados?'),
            content: const Text(
              'As alterações locais serão substituídas pelos dados de demonstração.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Restaurar'),
              ),
            ],
          ),
        ) ??
        false;

    if (ok && context.mounted) {
      context.read<FinanceStore>().resetDemo();
    }
  }
}

Future<void> _showQuickActions(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adicionar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.05,
              children: [
                _quick(
                  sheetContext,
                  Icons.north_east_rounded,
                  'Despesa',
                  FinoraColors.expense,
                  () {
                    Navigator.pop(sheetContext);
                    showTransactionForm(context, TransactionType.expense);
                  },
                ),
                _quick(
                  sheetContext,
                  Icons.south_west_rounded,
                  'Receita',
                  FinoraColors.income,
                  () {
                    Navigator.pop(sheetContext);
                    showTransactionForm(context, TransactionType.income);
                  },
                ),
                _quick(
                  sheetContext,
                  Icons.swap_horiz_rounded,
                  'Transferir',
                  FinoraColors.balance,
                  () {
                    Navigator.pop(sheetContext);
                    showTransferForm(context);
                  },
                ),
                _quick(
                  sheetContext,
                  Icons.show_chart_rounded,
                  'Investir',
                  FinoraColors.investment,
                  () {
                    Navigator.pop(sheetContext);
                    showInvestmentForm(context);
                  },
                ),
                _quick(
                  sheetContext,
                  Icons.track_changes_rounded,
                  'Meta',
                  FinoraColors.goal,
                  () {
                    Navigator.pop(sheetContext);
                    showGoalForm(context);
                  },
                ),
                _quick(
                  sheetContext,
                  Icons.shield_outlined,
                  'Reserva',
                  FinoraColors.warning,
                  () {
                    Navigator.pop(sheetContext);
                    showReserveForm(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _quick(BuildContext context, IconData icon, String label, Color color,
        VoidCallback onTap) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );

Future<void> showTransactionForm(
    BuildContext context, TransactionType type) async {
  final store = context.read<FinanceStore>();
  if (store.data.accounts.isEmpty) return;

  final title = TextEditingController();
  final amount = TextEditingController();
  final categories = type == TransactionType.income
      ? ['Renda', 'Renda extra', 'Venda', 'Reembolso', 'Outros']
      : [
          'Alimentação',
          'Transporte',
          'Moradia',
          'Saúde',
          'Lazer',
          'Compras',
          'Tecnologia',
          'Pets',
          'Outros'
        ];

  var category = categories.first;
  var account = store.data.accounts.first.name;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 18),
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type == TransactionType.income ? 'Nova entrada' : 'Nova saída',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setLocal(() => category = v);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: account,
              decoration: const InputDecoration(labelText: 'Conta'),
              items: store.data.accounts
                  .map((e) =>
                      DropdownMenuItem(value: e.name, child: Text(e.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setLocal(() => account = v);
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final value =
                      double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                  if (value <= 0 || title.text.trim().isEmpty) return;
                  store.addTransaction(
                    TransactionItem(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      type: type,
                      title: title.text.trim(),
                      category: category,
                      amount: value,
                      date: DateTime.now(),
                      account: account,
                    ),
                  );
                  Navigator.pop(sheetContext);
                },
                child: const Text('Salvar movimentação'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showTransferForm(BuildContext context) async {
  final store = context.read<FinanceStore>();
  if (store.data.accounts.length < 2) return;

  final amount = TextEditingController();
  final title = TextEditingController(text: 'Transferência');
  var from = store.data.accounts.first.name;
  var to = store.data.accounts[1].name;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 18),
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nova transferência',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: from,
              decoration: const InputDecoration(labelText: 'Origem'),
              items: store.data.accounts
                  .map((e) =>
                      DropdownMenuItem(value: e.name, child: Text(e.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setLocal(() => from = v);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: to,
              decoration: const InputDecoration(labelText: 'Destino'),
              items: store.data.accounts
                  .map((e) =>
                      DropdownMenuItem(value: e.name, child: Text(e.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setLocal(() => to = v);
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final value =
                      double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                  if (value <= 0 || from == to) return;
                  store.transfer(
                    amount: value,
                    from: from,
                    to: to,
                    title: title.text.trim().isEmpty
                        ? 'Transferência'
                        : title.text.trim(),
                  );
                  Navigator.pop(sheetContext);
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

class SimpleField {
  final String label;
  final TextEditingController controller;
  final bool number;

  SimpleField(this.label, this.controller, {this.number = false});
}

Future<void> _simpleForm(
  BuildContext context,
  String title,
  List<SimpleField> fields,
  bool Function() onSave,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          ...fields.expand(
            (field) => [
              TextField(
                controller: field.controller,
                keyboardType: field.number
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                decoration: InputDecoration(labelText: field.label),
              ),
              const SizedBox(height: 10),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (onSave()) Navigator.pop(sheetContext);
              },
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showBudgetForm(BuildContext context) async {
  final name = TextEditingController();
  final limit = TextEditingController();

  await _simpleForm(
    context,
    'Novo orçamento',
    [
      SimpleField('Categoria', name),
      SimpleField('Limite mensal', limit, number: true),
    ],
    () {
      final value = double.tryParse(limit.text.replaceAll(',', '.')) ?? 0;
      if (name.text.trim().isEmpty || value <= 0) return false;
      context.read<FinanceStore>().addBudget(
            BudgetItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              category: name.text.trim(),
              limit: value,
            ),
          );
      return true;
    },
  );
}

Future<void> showGoalForm(BuildContext context) async {
  final name = TextEditingController();
  final target = TextEditingController();
  final saved = TextEditingController(text: '0');

  await _simpleForm(
    context,
    'Nova meta',
    [
      SimpleField('Nome', name),
      SimpleField('Valor alvo', target, number: true),
      SimpleField('Valor inicial', saved, number: true),
    ],
    () {
      final targetValue =
          double.tryParse(target.text.replaceAll(',', '.')) ?? 0;
      final savedValue = double.tryParse(saved.text.replaceAll(',', '.')) ?? 0;
      if (name.text.trim().isEmpty || targetValue <= 0) return false;

      context.read<FinanceStore>().addGoal(
            GoalItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name.text.trim(),
              target: targetValue,
              saved: savedValue,
              deadline: DateTime.now().add(const Duration(days: 365)),
            ),
          );
      return true;
    },
  );
}

Future<void> showReserveForm(BuildContext context) async {
  final name = TextEditingController(text: 'Reserva de emergência');
  final target = TextEditingController();
  final saved = TextEditingController(text: '0');

  await _simpleForm(
    context,
    'Nova reserva',
    [
      SimpleField('Nome', name),
      SimpleField('Valor alvo', target, number: true),
      SimpleField('Valor inicial', saved, number: true),
    ],
    () {
      final targetValue =
          double.tryParse(target.text.replaceAll(',', '.')) ?? 0;
      final savedValue = double.tryParse(saved.text.replaceAll(',', '.')) ?? 0;
      if (name.text.trim().isEmpty || targetValue <= 0) return false;

      context.read<FinanceStore>().addReserve(
            ReserveItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name.text.trim(),
              target: targetValue,
              saved: savedValue,
              months: 6,
            ),
          );
      return true;
    },
  );
}

Future<void> showInvestmentForm(BuildContext context) async {
  final name = TextEditingController();
  final amount = TextEditingController();
  final estimatedReturn = TextEditingController(text: '0');

  await _simpleForm(
    context,
    'Novo investimento',
    [
      SimpleField('Ativo / investimento', name),
      SimpleField('Valor', amount, number: true),
      SimpleField('Rentabilidade estimada (%)', estimatedReturn, number: true),
    ],
    () {
      final amountValue =
          double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
      final returnValue =
          double.tryParse(estimatedReturn.text.replaceAll(',', '.')) ?? 0;
      if (name.text.trim().isEmpty || amountValue <= 0) return false;

      context.read<FinanceStore>().addInvestment(
            InvestmentItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name.text.trim(),
              assetClass: 'Renda fixa',
              amount: amountValue,
              estimatedReturn: returnValue,
            ),
          );
      return true;
    },
  );
}

Future<void> showAccountForm(BuildContext context) async {
  final name = TextEditingController();
  final balance = TextEditingController(text: '0');

  await _simpleForm(
    context,
    'Nova conta',
    [
      SimpleField('Nome', name),
      SimpleField('Saldo inicial', balance, number: true),
    ],
    () {
      final balanceValue =
          double.tryParse(balance.text.replaceAll(',', '.')) ?? 0;
      if (name.text.trim().isEmpty) return false;

      context.read<FinanceStore>().addAccount(
            AccountItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name.text.trim(),
              type: 'Conta digital',
              balance: balanceValue,
            ),
          );
      return true;
    },
  );
}

Future<void> showCardForm(BuildContext context) async {
  final name = TextEditingController();
  final limit = TextEditingController();
  final used = TextEditingController(text: '0');

  await _simpleForm(
    context,
    'Novo cartão',
    [
      SimpleField('Nome', name),
      SimpleField('Limite', limit, number: true),
      SimpleField('Fatura atual', used, number: true),
    ],
    () {
      final limitValue = double.tryParse(limit.text.replaceAll(',', '.')) ?? 0;
      final usedValue = double.tryParse(used.text.replaceAll(',', '.')) ?? 0;
      if (name.text.trim().isEmpty || limitValue <= 0) return false;

      context.read<FinanceStore>().addCard(
            CardItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name.text.trim(),
              limit: limitValue,
              used: usedValue,
              closeDay: 25,
              dueDay: 5,
            ),
          );
      return true;
    },
  );
}

Future<void> showContribution(
    BuildContext context, bool isGoal, String id) async {
  final controller = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Adicionar aporte'),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Valor'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final value =
                double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
            if (value <= 0) return;
            if (isGoal) {
              context.read<FinanceStore>().contributeGoal(id, value);
            } else {
              context.read<FinanceStore>().contributeReserve(id, value);
            }
            Navigator.pop(dialogContext);
          },
          child: const Text('Adicionar'),
        ),
      ],
    ),
  );
}
