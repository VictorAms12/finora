import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_database.dart';
import 'models.dart';
import 'store.dart';

/// FinanceStore com persistência primária em SQLite.
///
/// O FinanceStore original continua sendo a fonte das regras de negócio. Esta
/// classe apenas envolve load/commit/flush para migrar e espelhar a persistência
/// sem mudar cálculos de saldo, faturas, recorrências ou planejamento.
class SqliteFinanceStore extends FinanceStore {
  static const _legacyKey = 'finora_data_v02';
  static const _legacyBackupKey = 'finora_data_v02_backup';
  static const _sqliteDirtyKey = 'finora_sqlite_needs_resync';

  final FinoraDatabase database;
  Future<void> _sqliteSaveChain = Future<void>.value();
  String? _lastSqliteRaw;
  bool _sqliteAvailable = false;
  String? _storageError;

  SqliteFinanceStore({FinoraDatabase? database})
    : database = database ?? FinoraDatabase();

  bool get sqliteAvailable => _sqliteAvailable;
  String? get storageError => _storageError;

  FinanceData? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return FinanceData.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> _mirrorToLegacy(String raw) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_legacyKey);
    if (current != null && current != raw && _decode(current) != null) {
      await prefs.setString(_legacyBackupKey, current);
    }
    await prefs.setString(_legacyKey, raw);
  }

  @override
  Future<void> load() async {
    String? sqlitePrimary;
    String? sqliteBackup;
    var databaseOpened = false;
    final prefs = await SharedPreferences.getInstance();
    final sqliteDirty = prefs.getBool(_sqliteDirtyKey) == true;

    try {
      sqlitePrimary = await database.readPrimaryRaw();
      sqliteBackup = await database.readBackupRaw();
      databaseOpened = true;
      _sqliteAvailable = true;
      _storageError = null;
    } catch (error, stackTrace) {
      _sqliteAvailable = false;
      _storageError = error.toString();
      await prefs.setBool(_sqliteDirtyKey, true);
      debugPrint('Finora SQLite: falha ao abrir banco; usando legado: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    // Se já existe estado válido no banco, ele é autoritativo. Espelhamos o
    // mesmo JSON na chave legada e deixamos o FinanceStore original executar
    // toda a normalização/migração de domínio já testada na v0.3.9.
    var databaseRaw = sqlitePrimary;
    var databaseData = _decode(databaseRaw);
    var recoveredDatabaseBackup = false;
    if (databaseData == null && sqlitePrimary != null) {
      databaseRaw = sqliteBackup;
      databaseData = _decode(databaseRaw);
      recoveredDatabaseBackup = databaseData != null;
    }

    if (!sqliteDirty && databaseData != null && databaseRaw != null) {
      await _mirrorToLegacy(databaseRaw);
    }

    // Quando o SQLite está vazio (primeira abertura da v0.4), o super.load()
    // importa normalmente os dados da v0.3.9 que continuam intactos em
    // SharedPreferences. Em caso de falha do driver, este mesmo caminho é o
    // fallback seguro e o aplicativo permanece utilizável.
    await super.load();

    if (databaseOpened) {
      try {
        final normalized = data.encode();
        await database.saveRaw(
          normalized,
          rotateBackup: databaseData != null && !recoveredDatabaseBackup,
        );
        _lastSqliteRaw = normalized;
        _sqliteAvailable = true;
        _storageError = null;
        await prefs.setBool(_sqliteDirtyKey, false);
        // Também garante que qualquer normalização feita pelo núcleo continue
        // disponível para uma eventual volta à v0.3.9 durante a migração.
        await _mirrorToLegacy(normalized);
      } catch (error, stackTrace) {
        _sqliteAvailable = false;
        _storageError = error.toString();
        await prefs.setBool(_sqliteDirtyKey, true);
        debugPrint('Finora SQLite: falha na migração inicial: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  void _queueSqliteSave(String raw) {
    if (!_sqliteAvailable || _lastSqliteRaw == raw) return;
    _lastSqliteRaw = raw;
    _sqliteSaveChain = _sqliteSaveChain.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sqliteDirtyKey, true);
      try {
        await database.saveRaw(raw);
        await _mirrorToLegacy(raw);
        await prefs.setBool(_sqliteDirtyKey, false);
      } catch (error, stackTrace) {
        _sqliteAvailable = false;
        _storageError = error.toString();
        debugPrint('Finora SQLite: falha ao persistir: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  @override
  void onStateCommitted(String raw) => _queueSqliteSave(raw);

  @override
  Future<void> flushPersistence() async {
    await super.flushPersistence();
    await _sqliteSaveChain;
  }

  Future<int> indexedFinanceRowCount() async {
    if (!_sqliteAvailable) return 0;
    try {
      return await database.indexedRowCount();
    } catch (_) {
      return 0;
    }
  }
}

extension FinanceStoreStorageStatus on FinanceStore {
  bool get sqliteActive =>
      this is SqliteFinanceStore &&
      (this as SqliteFinanceStore).sqliteAvailable;

  String? get sqliteFailure => this is SqliteFinanceStore
      ? (this as SqliteFinanceStore).storageError
      : 'Armazenamento SQLite não inicializado.';
}
