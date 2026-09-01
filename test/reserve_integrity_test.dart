import 'package:finora/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reduzir valor alvo preserva o valor já guardado', () {
    final store = FinanceStore();
    expect(
      store.addReserve('Emergência', 5000, 4000, months: 6),
      isTrue,
    );

    final reserve = store.data.reserves.single;
    expect(
      store.updateReserve(reserve, 'Emergência', 3000, 4000, 6),
      isTrue,
    );

    expect(reserve.target, 3000);
    expect(reserve.saved, 4000);
  });

  test('aporte pode ultrapassar a meta sem perder valor', () {
    final store = FinanceStore();
    expect(
      store.addReserve('Emergência', 3000, 2900, months: 6),
      isTrue,
    );

    final reserve = store.data.reserves.single;
    store.contributeReserve(reserve.id, 500);

    expect(reserve.saved, 3400);
    expect(reserve.target, 3000);
  });

  test('retirada reduz a reserva e não permite saldo negativo', () {
    final store = FinanceStore();
    expect(
      store.addReserve('Emergência', 5000, 1200, months: 6),
      isTrue,
    );

    final reserve = store.data.reserves.single;
    expect(store.withdrawReserve(reserve.id, 200), isTrue);
    expect(reserve.saved, 1000);

    expect(store.withdrawReserve(reserve.id, 1200), isFalse);
    expect(reserve.saved, 1000);
  });

  test('reserva rejeita valor guardado negativo e limita meses', () {
    final store = FinanceStore();

    expect(
      store.addReserve('Inválida', 5000, -1, months: 6),
      isFalse,
    );
    expect(store.data.reserves, isEmpty);

    expect(
      store.addReserve('Emergência', 5000, 100, months: 100),
      isTrue,
    );
    expect(store.data.reserves.single.months, 60);
  });
}
