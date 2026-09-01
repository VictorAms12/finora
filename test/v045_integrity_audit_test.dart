import 'dart:convert';

import 'package:finora/local_database.dart';
import 'package:finora/models.dart';
import 'package:finora/sqlite_store.dart';
import 'package:finora/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  FinanceStore baseStore() {
    final store = FinanceStore();
    store.data.accounts.addAll([
      AccountItem(id: 'a1', name: 'Principal', type: 'Conta', balance: 1000),
      AccountItem(id: 'a2', name: 'Secundária', type: 'Conta', balance: 100),
    ]);
    return store;
  }

  test('meta reduzida preserva valor já acumulado e aceita excedente', () {
    final store = baseStore();
    expect(store.addGoal('Notebook', 5000, 4000, DateTime(2027)), isTrue);
    final goal = store.data.goals.single;
    expect(store.updateGoal(goal, 'Notebook', 3000, 4000, DateTime(2027)), isTrue);
    expect(goal.saved, 4000);
    store.contributeGoal(goal.id, 500);
    expect(goal.saved, 4500);
  });

  test('disponível considera compromissos reais e não desconta sugestão de meta', () {
    final store = baseStore();
    store.data.goals.add(GoalItem(
      id: 'g1', name: 'Meta', target: 1000, saved: 0, deadline: DateTime(2027),
    ));
    expect(store.availableToSpend, 1100);
    expect(store.suggestedGoalContribution, 200);
  });

  test('déficit de compromissos fica visível sem tornar disponível negativo', () {
    final store = baseStore();
    store.data.planned.add(PlannedItem(
      id: 'p1', type: TransactionType.expense, title: 'Conta', category: 'Serviços',
      amount: 1500, date: DateTime.now(), sourceName: 'Principal',
    ));
    expect(store.availableToSpend, 0);
    expect(store.currentCashShortfall, 400);
  });

  test('editar datas do cartão não move compras históricas de fatura', () {
    final store = baseStore();
    final card = CardItem(
      id: 'c1', name: 'Cartão', limit: 5000, used: 100,
      closeDay: 25, dueDay: 5, defaultAccountName: 'Principal',
    );
    store.data.cards.add(card);
    final historicalInvoice = DateTime(2026, 9);
    store.addTransaction(TransactionItem(
      id: 'tx1', type: TransactionType.expense, title: 'Compra', category: 'Compras',
      amount: 100, date: DateTime(2026, 8, 20), account: 'Cartão',
      paymentKind: PaymentKind.card, cardId: card.id, invoiceMonth: historicalInvoice,
    ));
    expect(store.updateCard(card, 'Cartão novo', 5000, 200, 10, 5, 'Principal'), isTrue);
    expect(store.data.transactions.single.invoiceMonth, historicalInvoice);
    expect(store.data.transactions.single.account, 'Cartão novo');
  });

  test('cartão não aceita saldo usado abaixo das compras pendentes rastreadas', () {
    final store = baseStore();
    final card = CardItem(id: 'c1', name: 'Cartão', limit: 5000, used: 0, closeDay: 25, dueDay: 5);
    store.data.cards.add(card);
    store.addTransaction(TransactionItem(
      id: 'tx1', type: TransactionType.expense, title: 'Compra', category: 'Compras',
      amount: 250, date: DateTime.now(), account: 'Cartão', paymentKind: PaymentKind.card, cardId: card.id,
    ));
    expect(store.updateCard(card, 'Cartão', 5000, 100, 25, 5, ''), isFalse);
    expect(card.used, 250);
  });

  test('conta e cartão com compromissos futuros não podem ser excluídos', () {
    final store = baseStore();
    store.data.planned.add(PlannedItem(
      id: 'p1', type: TransactionType.expense, title: 'Conta', category: 'Serviços',
      amount: 20, date: DateTime.now().add(const Duration(days: 5)), sourceName: 'Principal',
    ));
    expect(store.deleteAccount('a1'), isFalse);

    final card = CardItem(id: 'c1', name: 'Cartão', limit: 1000, used: 0, closeDay: 25, dueDay: 5);
    store.data.cards.add(card);
    store.data.planned.add(PlannedItem(
      id: 'p2', type: TransactionType.expense, title: 'Cartão', category: 'Compras',
      amount: 20, date: DateTime.now().add(const Duration(days: 5)),
      sourceName: 'Cartão', paymentKind: PaymentKind.card, cardId: card.id,
    ));
    expect(store.deleteCard(card.id), isFalse);
  });

  test('categoria em uso não pode trocar entre despesa e receita', () {
    final store = baseStore();
    final category = CategoryItem(id: 'cat', name: 'Projeto', income: false);
    store.data.categories.add(category);
    store.data.transactions.add(TransactionItem(
      id: 'tx', type: TransactionType.expense, title: 'Teste', category: 'Projeto',
      amount: 10, date: DateTime.now(), account: 'Principal',
    ));
    expect(store.updateCategory(category, 'Projeto', true), isFalse);
    expect(category.income, isFalse);
  });

  test('apagar ocorrência recorrente realizada não faz ela reaparecer', () {
    final store = baseStore();
    final today = DateTime.now();
    expect(store.addRecurring(
      type: TransactionType.expense, title: 'Mensalidade', category: 'Serviços', amount: 40,
      sourceName: 'Principal', paymentKind: PaymentKind.account,
      frequency: RecurrenceFrequency.monthly, startDate: today, maxOccurrences: 2,
    ), isTrue);
    final tx = store.data.transactions.singleWhere((e) => e.recurrenceId != null);
    final canonical = tx.recurrenceDate ?? tx.date;
    store.deleteTransaction(tx);
    store.refreshRecurringPlanning(persist: false);
    final occurrence = store.data.planned.where((e) =>
      e.recurrenceId != null && store.sameDay(e.canonicalRecurrenceDate, canonical)).toList();
    expect(occurrence, hasLength(1));
    expect(occurrence.single.status, PlannedStatus.skipped);
  });

  test('apagar parcela realizada devolve a parcela ao planejamento', () {
    final store = baseStore();
    expect(store.addInstallment(
      title: 'Compra', category: 'Compras', totalAmount: 200, installments: 2,
      sourceName: 'Principal', paymentKind: PaymentKind.account, startDate: DateTime.now(),
    ), isTrue);
    final tx = store.data.transactions.singleWhere((e) => e.installmentNumber == 1);
    store.deleteTransaction(tx);
    final restored = store.data.planned.singleWhere((e) => e.installmentNumber == 1);
    expect(restored.status, PlannedStatus.planned);
    expect(store.findAccount('Principal')!.balance, 1000);
  });

  test('falha SQLite não deixa estado antigo sobrescrever o espelho mais novo no restart', () async {
    final database = _FailOnceDatabase(
      factoryOverride: databaseFactoryFfi,
      pathOverride: inMemoryDatabasePath,
    );
    final first = SqliteFinanceStore(database: database);
    await first.load();
    expect(first.addAccount('Conta', 100), isTrue);
    await first.flushPersistence();

    database.failNextSave = true;
    first.data.accounts.single.balance = 250;
    first.commit();
    await first.flushPersistence();
    expect(first.sqliteAvailable, isFalse);

    final prefs = await SharedPreferences.getInstance();
    final legacy = FinanceData.fromJson(
      Map<String, dynamic>.from(jsonDecode(prefs.getString('finora_data_v02')!) as Map),
    );
    expect(legacy.accounts.single.balance, 250);
    expect(prefs.getBool('finora_sqlite_needs_resync'), isTrue);

    final second = SqliteFinanceStore(database: database);
    await second.load();
    expect(second.data.accounts.single.balance, 250);
    expect(second.sqliteAvailable, isTrue);
    expect(prefs.getBool('finora_sqlite_needs_resync'), isFalse);

    final sqlite = FinanceData.fromJson(
      Map<String, dynamic>.from(jsonDecode((await database.readPrimaryRaw())!) as Map),
    );
    expect(sqlite.accounts.single.balance, 250);
    await database.close();
  });
}

class _FailOnceDatabase extends FinoraDatabase {
  bool failNextSave = false;

  _FailOnceDatabase({super.factoryOverride, super.pathOverride});

  @override
  Future<void> saveRaw(String raw, {bool rotateBackup = true}) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('falha simulada de escrita');
    }
    await super.saveRaw(raw, rotateBackup: rotateBackup);
  }
}
