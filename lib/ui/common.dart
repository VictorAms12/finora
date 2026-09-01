import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store.dart';
import '../theme.dart';

export 'tiles.dart';

const monthShort = [
  'JAN',
  'FEV',
  'MAR',
  'ABR',
  'MAI',
  'JUN',
  'JUL',
  'AGO',
  'SET',
  'OUT',
  'NOV',
  'DEZ',
];

const monthLong = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${monthShort[date.month - 1]}';

String fullDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String monthLabel(DateTime date) => '${monthLong[date.month - 1]} ${date.year}';

String formatMoney(double value) {
  final negative = value < 0;
  final parts = value.abs().toStringAsFixed(2).split('.');
  final raw = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    buffer.write(raw[i]);
    final remaining = raw.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  final result = 'R\$ ${buffer.toString()},${parts[1]}';
  return negative ? '-$result' : result;
}

double? parseNumberInput(String raw) {
  var value = raw
      .trim()
      .replaceAll('R\$', '')
      .replaceAll(' ', '')
      .replaceAll('\u00a0', '');
  if (value.isEmpty) return null;
  final comma = value.lastIndexOf(',');
  final dot = value.lastIndexOf('.');
  if (comma >= 0 && dot >= 0) {
    if (comma > dot) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else {
      value = value.replaceAll(',', '');
    }
  } else if (comma >= 0) {
    value = value.replaceAll(',', '.');
  } else if (value.split('.').length > 2) {
    final last = value.lastIndexOf('.');
    value =
        value.substring(0, last).replaceAll('.', '') + value.substring(last);
  }
  final parsed = double.tryParse(value);
  return parsed != null && parsed.isFinite ? parsed : null;
}

String money(BuildContext context, double value) {
  final privacy = context.select<FinanceStore, bool>(
    (store) => store.data.privacyMode,
  );
  return privacy ? 'R\$ ••••••' : formatMoney(value);
}

TextStyle eyebrowStyle(BuildContext context) => TextStyle(
  fontSize: 8.5,
  letterSpacing: 1.3,
  fontWeight: FontWeight.w800,
  color: Theme.of(context).colorScheme.onSurfaceVariant,
);

IconData categoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('aliment')) return Icons.restaurant_rounded;
  if (value.contains('transporte') || value.contains('combust'))
    return Icons.directions_car_rounded;
  if (value.contains('moradia')) return Icons.home_rounded;
  if (value.contains('saúde') || value.contains('farm'))
    return Icons.health_and_safety_rounded;
  if (value.contains('lazer')) return Icons.sports_esports_rounded;
  if (value.contains('tecnologia')) return Icons.devices_rounded;
  if (value.contains('pet')) return Icons.pets_rounded;
  if (value.contains('educa')) return Icons.school_rounded;
  if (value.contains('serviço')) return Icons.receipt_long_rounded;
  if (value.contains('cartão')) return Icons.credit_card_rounded;
  if (value.contains('renda')) return Icons.payments_rounded;
  if (value.contains('venda')) return Icons.sell_rounded;
  if (value.contains('reembolso')) return Icons.replay_rounded;
  return Icons.category_rounded;
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
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverAppBar(
        floating: true,
        snap: true,
        toolbarHeight: 68,
        titleSpacing: 18,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eyebrow, style: eyebrowStyle(context)),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: actions,
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 108),
        sliver: SliverToBoxAdapter(child: child),
      ),
    ],
  );
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: borderColor ?? Theme.of(context).dividerColor,
        ),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: content,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
    child: Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: FinoraColors.gold.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: FinoraColors.goldBright),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.3,
            height: 1.45,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class MonthSwitcher extends StatelessWidget {
  final bool compact;

  const MonthSwitcher({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final selectedMonth = context.select<FinanceStore, DateTime>(
      (store) => store.selectedMonth,
    );
    final store = context.read<FinanceStore>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            visualDensity: VisualDensity.compact,
            onPressed: store.previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          InkWell(
            onTap: () => showMonthPicker(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 5 : 10,
                vertical: 8,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, .12),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  monthLabel(selectedMonth),
                  key: ValueKey('${selectedMonth.year}-${selectedMonth.month}'),
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            visualDensity: VisualDensity.compact,
            onPressed: store.nextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

Future<void> showMonthPicker(BuildContext context) async {
  final store = context.read<FinanceStore>();
  var year = store.selectedMonth.year;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (_, setLocal) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setLocal(() => year--),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '$year',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setLocal(() => year++),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.0,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (_, index) {
                  final month = index + 1;
                  final active =
                      store.selectedMonth.year == year &&
                      store.selectedMonth.month == month;
                  return InkWell(
                    onTap: () {
                      _moveStoreToMonth(store, DateTime(year, month));
                      Navigator.pop(sheetContext);
                    },
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? FinoraColors.gold.withValues(alpha: .14)
                            : null,
                        border: Border.all(
                          color: active
                              ? FinoraColors.goldBright
                              : Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        monthShort[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: active ? FinoraColors.goldBright : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    store.currentMonth();
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.today_rounded),
                  label: const Text('Ir para o mês atual'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _moveStoreToMonth(FinanceStore store, DateTime target) {
  store.selectMonth(target);
}

Widget sectionTitle(BuildContext context, String eyebrow, String title) =>
    Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: eyebrowStyle(context)),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
