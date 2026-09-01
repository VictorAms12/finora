part of 'store.dart';

enum FinoraInsightSeverity { info, attention, warning }

class FinoraInsight {
  final String title;
  final String message;
  final String question;
  final FinoraInsightSeverity severity;

  const FinoraInsight({
    required this.title,
    required this.message,
    required this.question,
    this.severity = FinoraInsightSeverity.info,
  });
}

extension FinanceStoreInsights on FinanceStore {
  List<FinoraInsight> get smartInsights {
    final insights = <FinoraInsight>[];
    final now = DateTime.now();
    final month = selectedMonth;

    if (selectedIsCurrent && overduePlannedCount > 0) {
      insights.add(
        FinoraInsight(
          title: 'Compromissos atrasados',
          message:
              '$overduePlannedCount item(ns) previsto(s) já passaram da data.',
          question: 'Quais compromissos estão atrasados?',
          severity: FinoraInsightSeverity.warning,
        ),
      );
    }

    if (selectedIsCurrent) {
      final today = DateTime(now.year, now.month, now.day);
      final limit = today.add(const Duration(days: 7));
      final nextSevenDays = data.planned
          .where(
            (item) =>
                item.status == PlannedStatus.planned &&
                item.type == TransactionType.expense &&
                !item.date.isBefore(today) &&
                !item.date.isAfter(limit),
          )
          .fold<double>(0, (sum, item) => sum + item.amount);
      if (nextSevenDays > 0) {
        insights.add(
          FinoraInsight(
            title: 'Próximos 7 dias',
            message:
                'Há R\$ ${nextSevenDays.toStringAsFixed(2).replaceAll('.', ',')} previstos para sair.',
            question: 'O que vence nos próximos 7 dias?',
            severity: nextSevenDays > cashBalance
                ? FinoraInsightSeverity.warning
                : FinoraInsightSeverity.attention,
          ),
        );
      }
    }

    final previous = expenseForMonth(DateTime(month.year, month.month - 1));
    final current = expenseForMonth(month);
    if (previous > 0 && current > previous * 1.20) {
      final percent = ((current - previous) / previous * 100).round();
      insights.add(
        FinoraInsight(
          title: 'Despesas aceleraram',
          message: 'Você está $percent% acima do mês anterior em despesas.',
          question: 'Por que meus gastos aumentaram?',
          severity: FinoraInsightSeverity.attention,
        ),
      );
    }

    final categoryMap = <String, double>{};
    for (final tx in transactionsForMonth(month)) {
      if (tx.type != TransactionType.expense) continue;
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
    }
    if (current > 0 && categoryMap.isNotEmpty) {
      final top = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final share = top.first.value / current;
      if (share >= .40) {
        insights.add(
          FinoraInsight(
            title: '${top.first.key} concentra seus gastos',
            message:
                '${(share * 100).round()}% das despesas do período estão nessa categoria.',
            question: 'Analise meus gastos em ${top.first.key}.',
          ),
        );
      }
    }

    if (selectedIsCurrent && now.day > 0) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (final budget in data.budgets) {
        final used = categoryMap[budget.category] ?? 0;
        if (budget.limit <= 0 || used <= 0) continue;
        final projected = used / now.day * daysInMonth;
        if (used <= budget.limit && projected > budget.limit * 1.05) {
          insights.add(
            FinoraInsight(
              title: 'Orçamento de ${budget.category} em risco',
              message: 'No ritmo atual, a categoria tende a ultrapassar o limite antes do fim do mês.',
              question: 'Como está meu orçamento de ${budget.category}?',
              severity: FinoraInsightSeverity.attention,
            ),
          );
        }
      }
    }

    for (final card in data.cards) {
      if (card.limit <= 0) continue;
      final ratio = card.used / card.limit;
      if (ratio >= .80) {
        insights.add(
          FinoraInsight(
            title: 'Limite do ${card.name}',
            message: '${(ratio * 100).round()}% do limite está comprometido.',
            question: 'Como está o ${card.name}?',
            severity: ratio >= .95
                ? FinoraInsightSeverity.warning
                : FinoraInsightSeverity.attention,
          ),
        );
      }
    }

    insights.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return insights.take(6).toList(growable: false);
  }
}
