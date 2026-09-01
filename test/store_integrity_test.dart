import 'package:finora/models.dart';
import 'package:finora/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  FinanceStore storeWithAccounts({double firstBalance = 1000}) {
    final store = FinanceStore();
    store.data.accounts.addAll([
      AccountItem(
        id: 'account-1',
        name: 'Conta principal',
        type: 'Conta corrente',
        balance: firstBalance,
      ),
      AccountItem(
        id: 'account-2',
        name: 'Reserva',
        type: 'Conta digital',
        balance: 300,
      ),
    ]);
    return store;
  }

  test('duas movimentações futuras manuais idênticas são preservadas', () {
    final store = storeWithAccounts();
    final future = DateTime.now().add(const Duration(days: 20));

    for (var i = 0; i < 2; i++) {
      store.addTransaction(TransactionItem(
        id: 'future-$i',
        type: TransactionType.expense,
        title: 'Conta repetida',
        category: 'Serviços',
        amount: 50,
        date: future,
        account: 'Conta principal',
      ));
    }

    expect(store.data.transactions, isEmpty);
    expect(store.data.planned, hasLength(2));
  });

  test('recorrência indefinida antiga mantém horizonte futuro rolante', () {
    final store = storeWithAccounts();
    final now = DateTime.now();
    final start = FinanceStore.addMonths(DateTime(now.year, now.month, 5), -36);

    store.data.recurringRules.add(RecurringRule(
      id: 'old-monthly',
      type: TransactionType.expense,
      title: 'Assinatura',
      category: 'Serviços',
      amount: 25,
      sourceName: 'Conta principal',
      paymentKind: PaymentKind.account,
      startDate: start,
      frequency: RecurrenceFrequency.monthly,
    ));

    store.refreshRecurringPlanning(persist: false);
    final today = DateTime(now.year, now.month, now.day);
    final future = store.data.planned
        .where((item) =>
            item.recurrenceId == 'old-monthly' &&
            item.status == PlannedStatus.planned &&
            item.date.isAfter(today))
        .toList();

    expect(future, hasLength(24));

    final ids = store.data.planned.map((item) => item.id).toSet();
    final count = store.data.planned.length;
    store.refreshRecurringPlanning(persist: false);
    expect(store.data.planned, hasLength(count));
    expect(store.data.planned.map((item) => item.id).toSet(), ids);
  });

  test('adiar recorrência não recria a ocorrência na data original', () {
    final store = storeWithAccounts();
    final start = FinanceStore.addMonths(DateTime.now(), 1);

    expect(
      store.addRecurring(
        type: TransactionType.expense,
        title: 'Internet',
        category: 'Serviços',
        amount: 99,
        sourceName: 'Conta principal',
        paymentKind: PaymentKind.account,
        frequency: RecurrenceFrequency.monthly,
        startDate: start,
        maxOccurrences: 3,
      ),
      isTrue,
    );

    final first = store.data.planned
        .where((item) => item.recurrenceId != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final item = first.first;
    final canonical = item.canonicalRecurrenceDate;
    final postponed = item.date.add(const Duration(days: 4));

    store.postponePlanned(item, postponed);
    store.refreshRecurringPlanning(persist: false);

    final sameOccurrence = store.data.planned
        .where((candidate) =>
            candidate.recurrenceId == item.recurrenceId &&
            store.sameDay(candidate.canonicalRecurrenceDate, canonical))
        .toList();
    expect(sameOccurrence, hasLength(1));
    expect(sameOccurrence.single.date, postponed);
  });

  test('ocorrência ignorada não reaparece após regenerar recorrência', () {
    final store = storeWithAccounts();
    final start = FinanceStore.addMonths(DateTime.now(), 1);
    store.addRecurring(
      type: TransactionType.expense,
      title: 'Streaming',
      category: 'Lazer',
      amount: 30,
      sourceName: 'Conta principal',
      paymentKind: PaymentKind.account,
      frequency: RecurrenceFrequency.monthly,
      startDate: start,
      maxOccurrences: 2,
    );

    final item = store.data.planned.firstWhere((e) => e.recurrenceId != null);
    final canonical = item.canonicalRecurrenceDate;
    store.skipPlanned(item);
    store.refreshRecurringPlanning(persist: false);

    final sameOccurrence = store.data.planned
        .where((candidate) =>
            candidate.recurrenceId == item.recurrenceId &&
            store.sameDay(candidate.canonicalRecurrenceDate, canonical))
        .toList();
    expect(sameOccurrence, hasLength(1));
    expect(sameOccurrence.single.status, PlannedStatus.skipped);
  });

  test('transferência futura vira previsão e só movimenta saldo ao realizar', () {
    final store = storeWithAccounts(firstBalance: 1000);
    final future = DateTime.now().add(const Duration(days: 10));

    expect(
      store.transfer(
        amount: 200,
        from: 'Conta principal',
        to: 'Reserva',
        date: future,
      ),
      isTrue,
    );

    expect(store.findAccount('Conta principal')!.balance, 1000);
    expect(store.findAccount('Reserva')!.balance, 300);
    expect(store.data.transactions, isEmpty);
    expect(store.data.planned, hasLength(1));
    expect(store.data.planned.single.type, TransactionType.transfer);
    expect(store.data.planned.single.destinationName, 'Reserva');

    expect(store.settlePlanned(store.data.planned.single), isTrue);
    expect(store.findAccount('Conta principal')!.balance, 800);
    expect(store.findAccount('Reserva')!.balance, 500);
  });

  test('próxima fatura não é cobrada como fatura atual', () {
    final store = storeWithAccounts(firstBalance: 1000);
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final next = DateTime(now.year, now.month + 1);

    store.data.cards.add(CardItem(
      id: 'card-1',
      name: 'Cartão',
      limit: 3000,
      used: 150,
      closeDay: 25,
      dueDay: 5,
      defaultAccountName: 'Conta principal',
    ));

    store.addTransaction(TransactionItem(
      id: 'next-invoice-purchase',
      type: TransactionType.expense,
      title: 'Compra próxima fatura',
      category: 'Compras',
      amount: 100,
      date: now,
      account: 'Cartão',
      paymentKind: PaymentKind.card,
      cardId: 'card-1',
      invoiceMonth: next,
    ));

    expect(store.findCard('card-1')!.used, 250);
    expect(store.invoiceOutstandingForMonth('card-1', current), 0);
    expect(store.invoiceOutstandingForMonth('card-1', next), 100);
    expect(store.manualCardOutstanding('card-1'), 150);

    expect(
      store.payInvoice(
        cardId: 'card-1',
        accountName: 'Conta principal',
        month: current,
      ),
      isTrue,
    );

    expect(store.findAccount('Conta principal')!.balance, 850);
    expect(store.findCard('card-1')!.used, 100);
    expect(store.invoiceOutstandingForMonth('card-1', next), 100);
  });

  test('excluir pagamento de fatura recompõe conta e cartão', () {
    final store = storeWithAccounts(firstBalance: 1000);
    final now = DateTime.now();
    store.data.cards.add(CardItem(
      id: 'card-1',
      name: 'Cartão',
      limit: 3000,
      used: 200,
      closeDay: 25,
      dueDay: 5,
      defaultAccountName: 'Conta principal',
    ));

    expect(
      store.payInvoice(
        cardId: 'card-1',
        accountName: 'Conta principal',
        month: DateTime(now.year, now.month),
      ),
      isTrue,
    );
    expect(store.findAccount('Conta principal')!.balance, 800);
    expect(store.findCard('card-1')!.used, 0);

    final payment = store.data.transactions.singleWhere(
      (tx) => tx.title.startsWith('Pagamento fatura'),
    );
    store.deleteTransaction(payment);

    expect(store.findAccount('Conta principal')!.balance, 1000);
    expect(store.findCard('card-1')!.used, 200);
  });

  test('lançamento previsto de hoje não é marcado como atrasado', () {
    final now = DateTime.now();
    final item = PlannedItem(
      id: 'today',
      type: TransactionType.expense,
      title: 'Hoje',
      category: 'Outros',
      amount: 10,
      date: DateTime(now.year, now.month, now.day),
    );
    expect(item.isOverdue, isFalse);
  });

  test('renomear categoria propaga para recorrências e parcelamentos', () {
    final store = storeWithAccounts();
    final category = CategoryItem(id: 'category-1', name: 'Antiga', income: false);
    store.data.categories.add(category);
    store.data.recurringRules.add(RecurringRule(
      id: 'rule-1',
      type: TransactionType.expense,
      title: 'Regra',
      category: 'Antiga',
      amount: 10,
      sourceName: 'Conta principal',
      paymentKind: PaymentKind.account,
      startDate: FinanceStore.addMonths(DateTime.now(), 1),
      frequency: RecurrenceFrequency.monthly,
    ));
    store.data.installmentPlans.add(InstallmentPlan(
      id: 'installment-1',
      title: 'Compra',
      category: 'Antiga',
      sourceName: 'Conta principal',
      paymentKind: PaymentKind.account,
      totalAmount: 100,
      installments: 2,
      startDate: DateTime.now(),
    ));

    expect(store.updateCategory(category, 'Nova', false), isTrue);
    expect(store.data.recurringRules.single.category, 'Nova');
    expect(store.data.installmentPlans.single.category, 'Nova');
  });

  test('commits rápidos persistem o estado mais recente em ordem', () async {
    final store = FinanceStore();
    await store.load();
    expect(store.addAccount('Conta', 100), isTrue);
    final account = store.data.accounts.single;

    for (var value = 101.0; value <= 120; value++) {
      account.balance = value;
      store.commit();
    }
    await store.flushPersistence();

    final restored = FinanceStore();
    await restored.load();
    expect(restored.data.accounts.single.balance, 120);
  });

  test('dados corrompidos recuperam última cópia íntegra', () async {
    final store = FinanceStore();
    await store.load();
    expect(store.addAccount('Conta', 100), isTrue);
    await store.flushPersistence();

    final account = store.data.accounts.single;
    account.balance = 200;
    store.commit();
    await store.flushPersistence();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('finora_data_v02', '{json quebrado');

    final recovered = FinanceStore();
    await recovered.load();
    expect(recovered.data.accounts.single.balance, 100);
  });

  test('nomes de contas não podem ficar ambíguos', () {
    final store = FinanceStore();
    expect(store.addAccount('Principal', 100), isTrue);
    expect(store.addAccount(' principal ', 50), isFalse);
    expect(store.data.accounts, hasLength(1));
  });
}
