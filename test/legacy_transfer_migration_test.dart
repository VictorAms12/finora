import 'package:finora/models.dart';
import 'package:finora/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('migração v0.3.9 estorna transferência futura já aplicada', () async {
    final store = FinanceStore();
    await store.load();

    store.data.accounts.addAll([
      AccountItem(
        id: 'source',
        name: 'Principal',
        type: 'Conta corrente',
        balance: 800,
      ),
      AccountItem(
        id: 'target',
        name: 'Reserva',
        type: 'Conta digital',
        balance: 500,
      ),
    ]);

    // Simula o estado legado: R$ 200 já saíram da origem e entraram no
    // destino, embora a transferência esteja programada para o futuro.
    store.data.transactions.add(
      TransactionItem(
        id: 'legacy-future-transfer',
        type: TransactionType.transfer,
        title: 'Transferência',
        category: 'Transferência',
        amount: 200,
        date: DateTime.now().add(const Duration(days: 15)),
        account: 'Principal → Reserva',
      ),
    );
    store.commit();
    await store.flushPersistence();

    await store.repairLegacyFutureTransferEffects();

    expect(store.findAccount('Principal')!.balance, 1000);
    expect(store.findAccount('Reserva')!.balance, 300);
    expect(store.data.transactions, isEmpty);
    expect(store.data.planned, hasLength(1));
    expect(store.data.planned.single.type, TransactionType.transfer);
    expect(store.data.planned.single.sourceName, 'Principal');
    expect(store.data.planned.single.destinationName, 'Reserva');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('finora_v039_future_transfer_repaired'), isTrue);
  });
}
