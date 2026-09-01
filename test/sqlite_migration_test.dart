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

  test('v0.4 migra SharedPreferences para SQLite sem perder dados', () async {
    final legacy = emptyData()
      ..onboardingCompleted = true
      ..accounts.add(
        AccountItem(
          id: 'legacy-account',
          name: 'Conta preservada',
          type: 'Conta digital',
          balance: 1234.56,
        ),
      );

    SharedPreferences.setMockInitialValues({
      'finora_data_v02': legacy.encode(),
    });

    final database = FinoraDatabase(
      factoryOverride: databaseFactoryFfi,
      pathOverride: inMemoryDatabasePath,
    );
    final store = SqliteFinanceStore(database: database);
    await store.load();

    expect(store.sqliteAvailable, isTrue);
    expect(store.data.accounts, hasLength(1));
    expect(store.data.accounts.single.name, 'Conta preservada');
    expect(store.data.accounts.single.balance, closeTo(1234.56, .001));

    final sqliteRaw = await database.readPrimaryRaw();
    expect(sqliteRaw, isNotNull);
    final sqliteData = FinanceData.fromJson(
      Map<String, dynamic>.from(jsonDecode(sqliteRaw!) as Map),
    );
    expect(sqliteData.accounts.single.name, 'Conta preservada');

    store.addTransaction(
      TransactionItem(
        id: 'tx-after-migration',
        type: TransactionType.expense,
        title: 'Teste pós-migração',
        category: 'Outros',
        amount: 10,
        date: DateTime.now(),
        account: 'Conta preservada',
      ),
    );
    await store.flushPersistence();

    expect(await database.indexedRowCount(), 1);
    expect(store.data.accounts.single.balance, closeTo(1224.56, .001));

    final prefs = await SharedPreferences.getInstance();
    final mirrorRaw = prefs.getString('finora_data_v02');
    expect(mirrorRaw, isNotNull);
    final mirrorData = FinanceData.fromJson(
      Map<String, dynamic>.from(jsonDecode(mirrorRaw!) as Map),
    );
    expect(
      mirrorData.transactions.any((e) => e.id == 'tx-after-migration'),
      isTrue,
    );

    await database.close();
  });

  test(
    'SQLite válido repara espelho legado corrompido no próximo load',
    () async {
      SharedPreferences.setMockInitialValues({});
      final database = FinoraDatabase(
        factoryOverride: databaseFactoryFfi,
        pathOverride: inMemoryDatabasePath,
      );
      final first = SqliteFinanceStore(database: database);
      await first.load();
      first.data.onboardingCompleted = true;
      first.data.accounts.add(
        AccountItem(
          id: 'sqlite-account',
          name: 'Conta do SQLite',
          type: 'Conta',
          balance: 99,
        ),
      );
      first.commit();
      await first.flushPersistence();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('finora_data_v02', '{corrompido');

      final second = SqliteFinanceStore(database: database);
      await second.load();

      expect(second.sqliteAvailable, isTrue);
      expect(second.data.accounts.single.name, 'Conta do SQLite');
      expect(_validJsonObject(prefs.getString('finora_data_v02')), isTrue);

      await database.close();
    },
  );
}

bool _validJsonObject(String? raw) {
  if (raw == null) return false;
  try {
    return jsonDecode(raw) is Map;
  } catch (_) {
    return false;
  }
}
