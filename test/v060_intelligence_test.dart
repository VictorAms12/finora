import 'package:finora/intelligence_engine.dart';
import 'package:finora/models.dart';
import 'package:finora/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  FinanceStore baseStore() {
    final store = FinanceStore();
    store.data.accounts.add(
      AccountItem(
        id: 'a1',
        name: 'Principal',
        type: 'Conta',
        balance: 3000,
      ),
    );
    return store;
  }

  TransactionItem expense(
    String id,
    String title,
    double amount,
    DateTime date, {
    String category = 'Serviços',
    String? installmentId,
    String? recurrenceId,
  }) =>
      TransactionItem(
        id: id,
        type: TransactionType.expense,
        title: title,
        category: category,
        amount: amount,
        date: date,
        account: 'Principal',
        installmentId: installmentId,
        recurrenceId: recurrenceId,
      );

  test('detecta cobrança mensal estável como possível assinatura', () {
    final store = baseStore();
    store.data.transactions.addAll([
      expense('n1', 'Netflix', 39.90, DateTime(2026, 6, 10)),
      expense('n2', 'Netflix', 39.90, DateTime(2026, 7, 10)),
      expense('n3', 'Netflix', 39.90, DateTime(2026, 8, 10)),
    ]);

    final report = const FinoraIntelligenceEngine().analyze(
      store,
      now: DateTime(2026, 9, 1),
    );

    expect(report.subscriptions, hasLength(1));
    expect(report.subscriptions.single.title, 'Netflix');
    expect(report.subscriptions.single.averageAmount, closeTo(39.90, .001));
    expect(report.subscriptions.single.nextExpectedDate, DateTime(2026, 9, 10));
  });

  test('não sugere parcela nem recorrência já cadastrada como assinatura', () {
    final store = baseStore();
    store.data.transactions.addAll([
      expense('p1', 'Notebook', 200, DateTime(2026, 6, 5), installmentId: 'i1'),
      expense('p2', 'Notebook', 200, DateTime(2026, 7, 5), installmentId: 'i1'),
      expense('p3', 'Notebook', 200, DateTime(2026, 8, 5), installmentId: 'i1'),
      expense('r1', 'Academia', 80, DateTime(2026, 6, 15), recurrenceId: 'r'),
      expense('r2', 'Academia', 80, DateTime(2026, 7, 15), recurrenceId: 'r'),
      expense('r3', 'Academia', 80, DateTime(2026, 8, 15), recurrenceId: 'r'),
    ]);

    final report = const FinoraIntelligenceEngine().analyze(
      store,
      now: DateTime(2026, 9, 1),
    );

    expect(report.subscriptions, isEmpty);
  });

  test('sinaliza possível cobrança duplicada sem alterar dados', () {
    final store = baseStore();
    store.data.transactions.addAll([
      expense('d1', 'Posto Avenida', 120, DateTime(2026, 8, 29), category: 'Transporte'),
      expense('d2', 'Posto Avenida', 120, DateTime(2026, 8, 29), category: 'Transporte'),
    ]);
    final before = store.data.encode();

    final report = const FinoraIntelligenceEngine().analyze(
      store,
      now: DateTime(2026, 9, 1),
    );

    expect(
      report.anomalies.any((item) => item.title.contains('duplicada')),
      isTrue,
    );
    expect(store.data.encode(), before);
  });

  test('orçamento ultrapassado reduz score e gera alerta crítico', () {
    final store = baseStore();
    store.data.budgets.add(
      BudgetItem(id: 'b1', category: 'Alimentação', limit: 300),
    );
    store.data.transactions.add(
      expense(
        'food',
        'Mercado',
        360,
        DateTime(2026, 9, 1),
        category: 'Alimentação',
      ),
    );

    final report = const FinoraIntelligenceEngine().analyze(
      store,
      now: DateTime(2026, 9, 1),
    );

    expect(report.healthScore, lessThan(100));
    expect(
      report.insights.any(
        (item) =>
            item.severity == IntelligenceSeverity.critical &&
            item.title.contains('ultrapassado'),
      ),
      isTrue,
    );
  });

  test('normalização aproxima descrições com acentos e números variáveis', () {
    expect(
      FinoraIntelligenceEngine.normalizeTitle('NETFLIX 123 - Assinatura'),
      FinoraIntelligenceEngine.normalizeTitle('Netflix 987 assinatura'),
    );
    expect(
      FinoraIntelligenceEngine.normalizeTitle('Pão & Café'),
      'pao cafe',
    );
  });
}
