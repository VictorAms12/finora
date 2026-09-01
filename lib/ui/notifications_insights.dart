import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threshold = today.add(
      Duration(days: store.data.notificationDaysBefore),
    );
    final pending =
        store.data.planned
            .where((item) => item.status == PlannedStatus.planned)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final overdue = pending.where((item) => item.isOverdue).toList();
    final upcoming = pending.where((item) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      return !date.isBefore(today) && !date.isAfter(threshold);
    }).toList();

    final notices = <_Notice>[
      ...overdue.map(
        (item) => _Notice(
          icon: Icons.error_outline_rounded,
          title: '${item.title} está atrasado',
          subtitle: '${fullDate(item.date)} · ${money(context, item.amount)}',
          color: FinoraColors.expense,
        ),
      ),
      ...upcoming.map(
        (item) => _Notice(
          icon: Icons.schedule_rounded,
          title: item.title,
          subtitle:
              'Previsto para ${fullDate(item.date)} · ${money(context, item.amount)}',
          color: FinoraColors.warning,
        ),
      ),
    ];

    for (final card in store.data.cards) {
      final amount = store.cardOutstandingDueForPlanningMonth(card.id, today);
      if (amount <= 0) continue;
      notices.add(
        _Notice(
          icon: Icons.credit_card_rounded,
          title: '${card.name} · fatura',
          subtitle: 'Vence dia ${card.dueDay} · ${money(context, amount)}',
          color: FinoraColors.expense,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: notices.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Tudo em dia',
                subtitle: 'Contas próximas, atrasos e avisos de fatura aparecerão aqui.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: notices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final notice = notices[index];
                return SurfaceCard(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: notice.color.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(notice.icon, color: notice.color, size: 20),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notice.title,
                              style: const TextStyle(
                                fontSize: 10.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              notice.subtitle,
                              style: TextStyle(
                                fontSize: 8.7,
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
              },
            ),
    );
  }
}

class _Notice {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _Notice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final income = store.monthIncome;
    final balance = store.monthBalance;
    final rate = income == 0 ? 0 : ((balance / income) * 100).round();
    final categories = store.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final overdue = store.overduePlannedCount;

    final texts = [
      'Taxa de economia no período: $rate%.',
      categories.isEmpty
          ? 'Registre despesas para identificar sua maior categoria de gasto.'
          : 'Maior categoria do período: ${categories.first.key}.',
      store.data.reserves.isEmpty
          ? 'Considere criar uma reserva de emergência.'
          : 'Reservas acumuladas: ${money(context, store.reserveBalance)}.',
      '${store.data.recurringRules.where((e) => e.active).length} recorrência(s) ativa(s) e ${store.data.installmentPlans.length} parcelamento(s).',
      overdue == 0
          ? 'Seu planejamento não possui compromissos atrasados.'
          : '$overdue compromisso(s) previsto(s) precisam de atenção.',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Conselhos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: texts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) => SurfaceCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FinoraColors.gold.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: FinoraColors.goldBright,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  texts[index],
                  style: const TextStyle(fontSize: 10, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
