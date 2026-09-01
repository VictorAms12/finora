import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora/models.dart';
import 'package:finora/store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  FinanceStore storeWithAccount({double balance = 1000}) {
    final store = FinanceStore();
    store.data.accounts.add(
      AccountItem(
        id: 'account-1',
        name: 'Conta principal',
        type: 'Conta corrente',
        balance: balance,
      ),
    );
    return store;
  }

  test('lançamento futuro vira previsto e não altera saldo atual', () {
    final store = storeWithAccount();
    final future = DateTime.now().add(const Duration(days: 35));

    store.addTransaction(
      TransactionItem(
        id: 'future-income',
        type: TransactionType.income,
        title: 'Receita futura',
        category: 'Renda',
        amount: 1500,
        date: future,
        account: 'Conta principal',
      ),
    );

    expect(store.cashBalance, 1000);
    expect(store.data.transactions, isEmpty);
    expect(store.data.planned, hasLength(1));
    expect(store.data.planned.single.amount, 1500);
    expect(store.data.planned.single.date, future);
  });

  test('salário no 5º dia útil é criado apenas como previsão futura', () {
    final store = storeWithAccount();
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month + 1);

    store.addSalaryOnFifthBusinessDay(
      amount: 2200,
      sourceName: 'Conta principal',
      startMonth: startMonth,
      maxOccurrences: 3,
    );

    expect(store.cashBalance, 1000);
    expect(store.data.transactions, isEmpty);
    expect(store.data.recurringRules, hasLength(1));

    final rule = store.data.recurringRules.single;
    expect(rule.id.startsWith('salary5-'), isTrue);

    final planned =
        store.data.planned
            .where((item) => item.recurrenceId == rule.id)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    expect(planned, hasLength(3));
    for (final item in planned) {
      final expected = store.fifthBusinessDayOfMonth(
        DateTime(item.date.year, item.date.month),
      );
      expect(item.date, expected);
      expect(item.date.weekday, isNot(DateTime.saturday));
      expect(item.date.weekday, isNot(DateTime.sunday));
    }
  });

  test(
    'migração v0.3.7 estorna receita futura órfã de recorrência excluída',
    () async {
      final store = storeWithAccount(balance: 3000);
      final now = DateTime.now();
      final future = DateTime(now.year, now.month + 1, 5);

      store.data.transactions.add(
        TransactionItem(
          id: 'legacy-future-salary',
          type: TransactionType.income,
          title: 'Salário',
          category: 'Renda',
          amount: 2000,
          date: future,
          account: 'Conta principal',
          recurrenceId: 'recurrence-that-was-deleted',
        ),
      );

      await store.repairLegacyFutureTransactionEffects();

      expect(store.cashBalance, 1000);
      expect(store.data.transactions, isEmpty);
      expect(store.data.planned, isEmpty);
    },
  );

  test('backup completo restaura contas e planejamento', () async {
    final source = storeWithAccount(balance: 2350);
    source.data.planned.add(
      PlannedItem(
        id: 'planned-1',
        type: TransactionType.expense,
        title: 'Internet',
        category: 'Serviços',
        amount: 99.90,
        date: DateTime.now().add(const Duration(days: 10)),
        sourceName: 'Conta principal',
      ),
    );

    final backup = source.exportBackupText();
    expect(backup.startsWith('FINORA-BACKUP-1:'), isTrue);

    final restored = FinanceStore();
    final success = await restored.restoreBackupText(backup);

    expect(success, isTrue);
    expect(restored.data.accounts, hasLength(1));
    expect(restored.data.accounts.single.balance, 2350);
    expect(restored.data.planned, hasLength(1));
    expect(restored.data.planned.single.title, 'Internet');
  });
}
