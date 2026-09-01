import 'dart:math' as math;

import 'models.dart';
import 'store.dart';

enum IntelligenceSeverity { info, warning, critical }

class IntelligenceInsight {
  final String id;
  final String title;
  final String message;
  final IntelligenceSeverity severity;
  final String? actionLabel;

  const IntelligenceInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.actionLabel,
  });
}

class SubscriptionCandidate {
  final String key;
  final String title;
  final String category;
  final double averageAmount;
  final int occurrences;
  final DateTime lastDate;
  final DateTime nextExpectedDate;
  final PaymentKind paymentKind;
  final String sourceName;
  final String? cardId;
  final double confidence;

  const SubscriptionCandidate({
    required this.key,
    required this.title,
    required this.category,
    required this.averageAmount,
    required this.occurrences,
    required this.lastDate,
    required this.nextExpectedDate,
    required this.paymentKind,
    required this.sourceName,
    required this.cardId,
    required this.confidence,
  });
}

class SpendingAnomaly {
  final String id;
  final String title;
  final String message;
  final double amount;
  final DateTime date;
  final IntelligenceSeverity severity;

  const SpendingAnomaly({
    required this.id,
    required this.title,
    required this.message,
    required this.amount,
    required this.date,
    required this.severity,
  });
}

class IntelligenceReport {
  final DateTime generatedAt;
  final int healthScore;
  final List<IntelligenceInsight> insights;
  final List<SubscriptionCandidate> subscriptions;
  final List<SpendingAnomaly> anomalies;

  const IntelligenceReport({
    required this.generatedAt,
    required this.healthScore,
    required this.insights,
    required this.subscriptions,
    required this.anomalies,
  });

  bool get hasAttention => insights.any(
        (item) => item.severity != IntelligenceSeverity.info,
      );
}

class FinoraIntelligenceEngine {
  const FinoraIntelligenceEngine();

  IntelligenceReport analyze(FinanceStore store, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final subscriptions = _detectSubscriptions(store, reference);
    final anomalies = _detectAnomalies(store, reference);
    final insights = _buildInsights(store, reference, subscriptions, anomalies);

    var score = 100;
    for (final insight in insights) {
      switch (insight.severity) {
        case IntelligenceSeverity.info:
          break;
        case IntelligenceSeverity.warning:
          score -= 8;
        case IntelligenceSeverity.critical:
          score -= 18;
      }
    }
    score -= math.min(anomalies.length * 4, 20);

    return IntelligenceReport(
      generatedAt: reference,
      healthScore: score.clamp(0, 100),
      insights: insights.take(8).toList(growable: false),
      subscriptions: subscriptions.take(12).toList(growable: false),
      anomalies: anomalies.take(8).toList(growable: false),
    );
  }

  List<SubscriptionCandidate> _detectSubscriptions(
    FinanceStore store,
    DateTime now,
  ) {
    final cutoff = DateTime(now.year, now.month - 8, 1);
    final groups = <String, List<TransactionItem>>{};

    for (final tx in store.data.transactions) {
      if (tx.type != TransactionType.expense ||
          tx.date.isBefore(cutoff) ||
          tx.recurrenceId != null ||
          tx.installmentId != null ||
          !tx.amount.isFinite ||
          tx.amount <= 0) {
        continue;
      }
      final normalized = normalizeTitle(tx.title);
      if (normalized.length < 3) continue;
      final source = tx.paymentKind == PaymentKind.card
          ? (store.findCard(tx.cardId)?.name ?? tx.account)
          : tx.account;
      final key = '$normalized|${tx.category.toLowerCase()}|${tx.paymentKind.name}|${source.toLowerCase()}';
      groups.putIfAbsent(key, () => <TransactionItem>[]).add(tx);
    }

    final result = <SubscriptionCandidate>[];
    for (final entry in groups.entries) {
      final items = entry.value..sort((a, b) => a.date.compareTo(b.date));
      final months = <String>{
        for (final item in items) '${item.date.year}-${item.date.month}',
      };
      if (months.length < 3) continue;

      final average = items.fold<double>(0, (sum, item) => sum + item.amount) /
          items.length;
      if (average <= 0) continue;
      final tolerance = math.max(2.0, average * .12);
      final stableAmounts = items
          .where((item) => (item.amount - average).abs() <= tolerance)
          .length;
      if (stableAmounts / items.length < .72) continue;

      var regularIntervals = 0;
      var checkedIntervals = 0;
      for (var i = 1; i < items.length; i++) {
        if (_sameMonth(items[i - 1].date, items[i].date)) continue;
        final days = items[i].date.difference(items[i - 1].date).inDays.abs();
        checkedIntervals++;
        if (days >= 24 && days <= 38) regularIntervals++;
      }
      if (checkedIntervals == 0 || regularIntervals / checkedIntervals < .6) {
        continue;
      }

      final first = items.first;
      final last = items.last;
      final alreadyTracked = store.data.recurringRules.any((rule) {
        if (!rule.active || rule.type != TransactionType.expense) return false;
        return normalizeTitle(rule.title) == normalizeTitle(last.title) &&
            (rule.amount - average).abs() <= tolerance;
      });
      if (alreadyTracked) continue;

      final sourceName = last.paymentKind == PaymentKind.card
          ? (store.findCard(last.cardId)?.name ?? last.account)
          : last.account;
      final confidence = (.66 +
              math.min(months.length, 6) * .045 +
              (regularIntervals / checkedIntervals) * .08 +
              (stableAmounts / items.length) * .05)
          .clamp(0.0, .97)
          .toDouble();

      result.add(
        SubscriptionCandidate(
          key: entry.key,
          title: last.title.trim().isEmpty ? first.title : last.title,
          category: last.category,
          averageAmount: average,
          occurrences: items.length,
          lastDate: last.date,
          nextExpectedDate: _addOneMonth(last.date),
          paymentKind: last.paymentKind,
          sourceName: sourceName,
          cardId: last.cardId,
          confidence: confidence,
        ),
      );
    }

    result.sort((a, b) => b.confidence.compareTo(a.confidence));
    return result;
  }

  List<SpendingAnomaly> _detectAnomalies(
    FinanceStore store,
    DateTime now,
  ) {
    final result = <SpendingAnomaly>[];
    final recent = store.data.transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              !tx.date.isBefore(now.subtract(const Duration(days: 62))) &&
              tx.amount > 0 &&
              tx.amount.isFinite,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final duplicateKeys = <String>{};
    for (var i = 0; i < recent.length; i++) {
      for (var j = i + 1; j < recent.length; j++) {
        final a = recent[i];
        final b = recent[j];
        if (a.date.difference(b.date).inDays.abs() > 1) continue;
        if ((a.amount - b.amount).abs() > .01) continue;
        if (normalizeTitle(a.title) != normalizeTitle(b.title)) continue;
        final key = '${normalizeTitle(a.title)}|${a.amount.toStringAsFixed(2)}|${_dayKey(a.date)}';
        if (!duplicateKeys.add(key)) continue;
        result.add(
          SpendingAnomaly(
            id: 'dup-$key',
            title: 'Possível cobrança duplicada',
            message:
                '${a.title} apareceu com o mesmo valor em datas muito próximas.',
            amount: a.amount,
            date: a.date,
            severity: IntelligenceSeverity.warning,
          ),
        );
      }
    }

    final currentMonth = DateTime(now.year, now.month);
    final currentByCategory = _expensesByCategory(store, currentMonth);
    for (final entry in currentByCategory.entries) {
      final previous = <double>[];
      for (var offset = 1; offset <= 3; offset++) {
        previous.add(
          _expensesByCategory(
            store,
            DateTime(currentMonth.year, currentMonth.month - offset),
          )[entry.key] ??
              0,
        );
      }
      final nonZero = previous.where((value) => value > 0).toList();
      if (nonZero.length < 2) continue;
      final average = nonZero.reduce((a, b) => a + b) / nonZero.length;
      if (average < 40 || entry.value < average * 1.65) continue;
      if (entry.value - average < 80) continue;
      result.add(
        SpendingAnomaly(
          id: 'spike-${entry.key}',
          title: 'Aumento fora do padrão',
          message:
              '${entry.key} está ${((entry.value / average - 1) * 100).round()}% acima da média recente.',
          amount: entry.value,
          date: now,
          severity: entry.value >= average * 2.2
              ? IntelligenceSeverity.critical
              : IntelligenceSeverity.warning,
        ),
      );
    }

    final amounts = recent.map((e) => e.amount).toList()..sort();
    if (amounts.length >= 6) {
      final median = amounts[amounts.length ~/ 2];
      for (final tx in recent.take(20)) {
        if (tx.amount >= math.max(250, median * 3.2)) {
          result.add(
            SpendingAnomaly(
              id: 'large-${tx.id}',
              title: 'Gasto bem acima do padrão',
              message:
                  '${tx.title} ficou muito acima do valor típico das suas despesas recentes.',
              amount: tx.amount,
              date: tx.date,
              severity: IntelligenceSeverity.info,
            ),
          );
        }
      }
    }

    final unique = <String, SpendingAnomaly>{};
    for (final item in result) {
      unique.putIfAbsent(item.id, () => item);
    }
    final values = unique.values.toList()
      ..sort((a, b) {
        final severity = b.severity.index.compareTo(a.severity.index);
        if (severity != 0) return severity;
        return b.date.compareTo(a.date);
      });
    return values;
  }

  List<IntelligenceInsight> _buildInsights(
    FinanceStore store,
    DateTime now,
    List<SubscriptionCandidate> subscriptions,
    List<SpendingAnomaly> anomalies,
  ) {
    final insights = <IntelligenceInsight>[];
    final today = DateTime(now.year, now.month, now.day);
    final overdue = store.data.planned.where((item) => item.isOverdue).toList();
    if (overdue.isNotEmpty) {
      final total = overdue.fold<double>(0, (sum, item) => sum + item.amount);
      insights.add(
        IntelligenceInsight(
          id: 'overdue',
          title: '${overdue.length} compromisso${overdue.length == 1 ? '' : 's'} atrasado${overdue.length == 1 ? '' : 's'}',
          message: 'Há R\$ ${_money(total)} aguardando revisão no planejamento.',
          severity: IntelligenceSeverity.critical,
          actionLabel: 'Ver planejamento',
        ),
      );
    }

    final weekEnd = today.add(const Duration(days: 7));
    final upcoming = store.data.planned.where((item) {
      if (!item.isPending) return false;
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      return !date.isBefore(today) && !date.isAfter(weekEnd);
    }).toList();
    if (upcoming.isNotEmpty) {
      final total = upcoming.fold<double>(0, (sum, item) => sum + item.amount);
      insights.add(
        IntelligenceInsight(
          id: 'upcoming',
          title: 'Próximos 7 dias',
          message:
              '${upcoming.length} compromisso${upcoming.length == 1 ? '' : 's'} somam R\$ ${_money(total)}.',
          severity: IntelligenceSeverity.warning,
          actionLabel: 'Conferir agenda',
        ),
      );
    }

    for (final budget in store.data.budgets) {
      final spent = _expensesByCategory(store, DateTime(now.year, now.month))[
              budget.category] ??
          0;
      if (budget.limit <= 0) continue;
      final ratio = spent / budget.limit;
      if (ratio >= 1) {
        insights.add(
          IntelligenceInsight(
            id: 'budget-${budget.id}',
            title: 'Orçamento de ${budget.category} ultrapassado',
            message:
                'R\$ ${_money(spent)} usados de R\$ ${_money(budget.limit)}.',
            severity: IntelligenceSeverity.critical,
          ),
        );
      } else if (ratio >= .8) {
        insights.add(
          IntelligenceInsight(
            id: 'budget-${budget.id}',
            title: '${budget.category} perto do limite',
            message:
                '${(ratio * 100).round()}% do orçamento já foi consumido.',
            severity: IntelligenceSeverity.warning,
          ),
        );
      }
    }

    for (final card in store.data.cards) {
      if (card.limit <= 0) continue;
      final ratio = card.used / card.limit;
      if (ratio >= .85) {
        insights.add(
          IntelligenceInsight(
            id: 'card-${card.id}',
            title: '${card.name} com uso elevado',
            message:
                '${(ratio * 100).round()}% do limite está comprometido.',
            severity: ratio >= 1
                ? IntelligenceSeverity.critical
                : IntelligenceSeverity.warning,
          ),
        );
      }
    }

    if (subscriptions.isNotEmpty) {
      final monthly = subscriptions.fold<double>(
        0,
        (sum, item) => sum + item.averageAmount,
      );
      insights.add(
        IntelligenceInsight(
          id: 'subscriptions',
          title: 'Padrões recorrentes encontrados',
          message:
              '${subscriptions.length} possível${subscriptions.length == 1 ? '' : 'is'} assinatura${subscriptions.length == 1 ? '' : 's'} ou cobrança${subscriptions.length == 1 ? '' : 's'} mensal${subscriptions.length == 1 ? '' : 'is'}, cerca de R\$ ${_money(monthly)}/mês.',
          severity: IntelligenceSeverity.info,
          actionLabel: 'Revisar recorrências',
        ),
      );
    }

    final seriousAnomalies = anomalies
        .where((item) => item.severity != IntelligenceSeverity.info)
        .length;
    if (seriousAnomalies > 0) {
      insights.add(
        IntelligenceInsight(
          id: 'anomalies',
          title: 'Movimentações para conferir',
          message:
              '$seriousAnomalies comportamento${seriousAnomalies == 1 ? '' : 's'} fora do seu padrão recente.',
          severity: IntelligenceSeverity.warning,
          actionLabel: 'Ver detalhes',
        ),
      );
    }

    insights.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return insights;
  }

  Map<String, double> _expensesByCategory(
    FinanceStore store,
    DateTime month,
  ) {
    final result = <String, double>{};
    for (final tx in store.data.transactions) {
      if (tx.type != TransactionType.expense || !_sameMonth(tx.date, month)) {
        continue;
      }
      result.update(tx.category, (value) => value + tx.amount,
          ifAbsent: () => tx.amount);
    }
    return result;
  }

  static String normalizeTitle(String input) {
    var value = input.trim().toLowerCase();
    const replacements = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    replacements.forEach((from, to) => value = value.replaceAll(from, to));
    value = value.replaceAll(RegExp(r'\b\d{1,4}\b'), ' ');
    value = value.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static DateTime _addOneMonth(DateTime date) {
    final target = DateTime(date.year, date.month + 1, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(target.year, target.month, math.min(date.day, lastDay));
  }

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static String _dayKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';

  static String _money(double value) => value.toStringAsFixed(2).replaceAll('.', ',');
}