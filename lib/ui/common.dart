import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

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

String monthLabel(DateTime date) =>
    '${monthLong[date.month - 1]} ${date.year}';

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

String money(BuildContext context, double value) {
  final privacy = context.watch<FinanceStore>().data.privacyMode;
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
  if (value.contains('transporte') || value.contains('combust')) {
    return Icons.directions_car_rounded;
  }
  if (value.contains('moradia')) return Icons.home_rounded;
  if (value.contains('saúde') || value.contains('farm')) {
    return Icons.health_and_safety_rounded;
  }
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
  Widget build(BuildContext context) {
    return CustomScrollView(
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
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
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
  Widget build(BuildContext context) {
    return Padding(
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
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
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
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class MonthSwitcher extends StatelessWidget {
  final bool compact;

  const MonthSwitcher({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Mês anterior',
          visualDensity: VisualDensity.compact,
          onPressed: store.previousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        InkWell(
          onTap: store.currentMonth,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 9,
              vertical: 7,
            ),
            child: Text(
              monthLabel(store.selectedMonth),
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w900,
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
    );
  }
}

Widget sectionTitle(
  BuildContext context,
  String eyebrow,
  String title,
) =>
    Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: eyebrowStyle(context)),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

export 'tiles.dart';
