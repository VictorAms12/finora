import 'package:finora/models.dart';
import 'package:finora/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  FinanceStore storeWithAccount() {
    final store = FinanceStore();
    store.data.accounts.add(
      AccountItem(
        id: 'a1',
        name: 'Conta principal',
        type: 'Conta digital',
        balance: 1000,
      ),
    );
    return store;
  }

  test('backup exportado pode ser inspecionado antes da restauração', () {
    final store = storeWithAccount();
    store.data.cards.add(
      CardItem(
        id: 'c1',
        name: 'Cartão',
        limit: 2000,
        used: 100,
        closeDay: 25,
        dueDay: 5,
      ),
    );

    final backup = store.exportBackupText();
    final info = store.inspectBackupText(backup);

    expect(info, isNotNull);
    expect(info!.accounts, 1);
    expect(info.cards, 1);
    expect(info.totalItems, 2);
    expect(store.data.lastBackupAt, isNotNull);
  });

  test('aporte vinculado a meta move saldo sem reduzir patrimônio', () {
    final store = storeWithAccount();
    expect(store.addGoal('Notebook', 3000, 100, DateTime(2027, 1, 1)), isTrue);
    final goal = store.data.goals.single;
    final before = store.netWorth;

    expect(
      store.moveGoalFunds(
        goalId: goal.id,
        value: 200,
        withdraw: false,
        accountName: 'Conta principal',
      ),
      isTrue,
    );

    expect(store.data.accounts.single.balance, 800);
    expect(goal.saved, 300);
    expect(store.linkedGoalBalance, 200);
    expect(store.netWorth, closeTo(before, 0.001));
    expect(store.fundingHistory(FundingTargetType.goal, goal.id), hasLength(1));

    expect(
      store.moveGoalFunds(
        goalId: goal.id,
        value: 50,
        withdraw: true,
        accountName: 'Conta principal',
      ),
      isTrue,
    );
    expect(store.data.accounts.single.balance, 850);
    expect(goal.saved, 250);
    expect(store.netWorth, closeTo(before, 0.001));
  });

  test('reserva vinculada atualiza conta e preserva patrimônio', () {
    final store = storeWithAccount();
    expect(store.addReserve('Emergência', 6000, 0), isTrue);
    final reserve = store.data.reserves.single;
    final before = store.netWorth;

    expect(
      store.moveReserveFunds(
        reserveId: reserve.id,
        value: 300,
        withdraw: false,
        accountName: 'Conta principal',
      ),
      isTrue,
    );

    expect(store.data.accounts.single.balance, 700);
    expect(reserve.saved, 300);
    expect(store.netWorth, closeTo(before, 0.001));

    expect(
      store.moveReserveFunds(
        reserveId: reserve.id,
        value: 400,
        withdraw: true,
        accountName: 'Conta principal',
      ),
      isFalse,
    );
  });
}