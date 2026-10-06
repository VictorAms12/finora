import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';
import 'accounts.dart';
import 'forms.dart';
import 'planning.dart';

enum _NoticeKind { overdue, upcoming, card, budget, projection }

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  _NoticeKind? _filter;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threshold =
        today.add(Duration(days: store.data.notificationDaysBefore));
    final pending = store.data.planned
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
          kind: _NoticeKind.overdue,
          icon: Icons.error_outline_rounded,
          title: '${item.title} está atrasado',
          subtitle: '${fullDate(item.date)} · ${money(context, item.amount)}',
          color: FinoraColors.expense,
          onTap: () => showPlannedDetails(context, item),
        ),
      ),
      ...upcoming.map(
        (item) => _Notice(
          kind: _NoticeKind.upcoming,
          icon: Icons.schedule_rounded,
          title: item.title,
          subtitle:
              'Previsto para ${fullDate(item.date)} · ${money(context, item.amount)}',
          color: FinoraColors.warning,
          onTap: () => showPlannedDetails(context, item),
        ),
      ),
    ];

    for (final card in store.data.cards) {
      final amount = store.cardOutstandingDueForPlanningMonth(card.id, today);
      final usage = card.limit <= 0 ? 0.0 : card.used / card.limit;
      if (amount > 0) {
        notices.add(
          _Notice(
            kind: _NoticeKind.card,
            icon: Icons.credit_card_rounded,
            title: '${card.name} · fatura',
            subtitle: 'Vence dia ${card.dueDay} · ${money(context, amount)}',
            color: FinoraColors.expense,
            onTap: () => Navigator.push(
              context,
              PremiumRoute(page: CardInvoiceScreen(cardId: card.id)),
            ),
          ),
        );
      }
      if (usage >= .80) {
        notices.add(
          _Notice(
            kind: _NoticeKind.card,
            icon: Icons.credit_score_outlined,
            title: '${card.name} · limite em atenção',
            subtitle:
                '${(usage * 100).round()}% usado · disponível ${money(context, card.available)}',
            color: usage >= 1 ? FinoraColors.expense : FinoraColors.warning,
            onTap: () => Navigator.push(
              context,
              PremiumRoute(page: CardInvoiceScreen(cardId: card.id)),
            ),
          ),
        );
      }
    }

    for (final budget in store.data.budgets) {
      final spent = store.expensesByCategory[budget.category] ?? 0;
      final ratio = budget.limit <= 0 ? 0.0 : spent / budget.limit;
      if (ratio < .80) continue;
      notices.add(
        _Notice(
          kind: _NoticeKind.budget,
          icon: Icons.speed_rounded,
          title: '${budget.category} · orçamento',
          subtitle: ratio >= 1
              ? 'Limite ultrapassado: ${money(context, spent)} de ${money(context, budget.limit)}'
              : '${(ratio * 100).round()}% usado · ${money(context, budget.limit - spent)} restantes',
          color: ratio >= 1 ? FinoraColors.expense : FinoraColors.warning,
          onTap: () => Navigator.push(
            context,
            PremiumRoute(page: const PlanningScreen()),
          ),
        ),
      );
    }

    final negativeMonth = store.firstProjectedNegativeMonth(monthsAhead: 6);
    if (negativeMonth != null) {
      notices.add(
        _Notice(
          kind: _NoticeKind.projection,
          icon: Icons.trending_down_rounded,
          title: 'Projeção de caixa negativa',
          subtitle:
              'Com os compromissos atuais, ${monthLabel(negativeMonth)} pode encerrar no negativo.',
          color: FinoraColors.expense,
          onTap: () => Navigator.push(
            context,
            PremiumRoute(page: const PlanningScreen()),
          ),
        ),
      );
    }

    final filtered = _filter == null
        ? notices
        : notices.where((notice) => notice.kind == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (_filter != null)
            IconButton(
              tooltip: 'Limpar filtro',
              onPressed: () => setState(() => _filter = null),
              icon: const Icon(Icons.filter_alt_off_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todos', null),
                _filterChip('Atrasados', _NoticeKind.overdue),
                _filterChip('Próximos', _NoticeKind.upcoming),
                _filterChip('Cartões', _NoticeKind.card),
                _filterChip('Orçamentos', _NoticeKind.budget),
                _filterChip('Projeções', _NoticeKind.projection),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const SurfaceCard(
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Tudo em dia',
                subtitle:
                    'Não há avisos correspondentes ao filtro selecionado.',
              ),
            )
          else
            ...filtered.map(
              (notice) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SurfaceCard(
                  onTap: notice.onTap,
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
                        child:
                            Icon(notice.icon, color: notice.color, size: 20),
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
                      if (notice.onTap != null)
                        const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _NoticeKind? kind) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == kind,
          onSelected: (_) => setState(() => _filter = kind),
        ),
      );
}

class _Notice {
  final _NoticeKind kind;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _Notice({
    required this.kind,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
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
