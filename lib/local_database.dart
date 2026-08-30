import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Camada SQLite do Finora.
///
/// A v0.4 mantém o modelo financeiro em memória para preservar o comportamento
/// já validado, mas usa SQLite como armazenamento primário transacional. O
/// snapshot completo permite uma migração segura do JSON legado, enquanto a
/// tabela [finance_index] deixa transações e previstos indexados para consultas
/// rápidas, relatórios e recursos de IA.
class FinoraDatabase {
  static const _databaseName = 'finora_v040.db';
  static const _databaseVersion = 1;

  final DatabaseFactory? factoryOverride;
  final String? pathOverride;
  Database? _db;

  FinoraDatabase({this.factoryOverride, this.pathOverride});

  DatabaseFactory _factory() {
    if (factoryOverride != null) return factoryOverride!;
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return mobile.databaseFactory;
  }

  Future<Database> _database() async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;

    final factory = _factory();
    final path = pathOverride ?? p.join(await factory.getDatabasesPath(), _databaseName);
    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          try {
            await db.execute('PRAGMA journal_mode = WAL');
            await db.execute('PRAGMA synchronous = NORMAL');
          } catch (_) {
            // Alguns drivers/testes em memória não aceitam WAL. A persistência
            // continua transacional mesmo sem essas otimizações.
          }
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE app_state (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              json TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE app_state_backup (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              json TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE finance_index (
              kind TEXT NOT NULL,
              id TEXT NOT NULL,
              type TEXT,
              title TEXT,
              category TEXT,
              amount REAL,
              date_ms INTEGER,
              account TEXT,
              json TEXT NOT NULL,
              PRIMARY KEY (kind, id)
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_finance_kind_date ON finance_index(kind, date_ms)',
          );
          await db.execute(
            'CREATE INDEX idx_finance_kind_category_date ON finance_index(kind, category, date_ms)',
          );
          await db.execute('''
            CREATE TABLE metadata (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    _db = database;
    return database;
  }

  Future<String?> readPrimaryRaw() async {
    final db = await _database();
    final rows = await db.query('app_state', columns: ['json'], where: 'id = 1');
    return rows.isEmpty ? null : rows.first['json'] as String?;
  }

  Future<String?> readBackupRaw() async {
    final db = await _database();
    final rows = await db.query(
      'app_state_backup',
      columns: ['json'],
      where: 'id = 1',
    );
    return rows.isEmpty ? null : rows.first['json'] as String?;
  }

  bool _isJsonObject(String raw) {
    try {
      return jsonDecode(raw) is Map;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveRaw(String raw, {bool rotateBackup = true}) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Estado financeiro precisa ser um objeto JSON.');
    }

    final db = await _database();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      if (rotateBackup) {
        final current = await txn.query(
          'app_state',
          columns: ['json'],
          where: 'id = 1',
        );
        if (current.isNotEmpty) {
          final previous = current.first['json'] as String?;
          if (previous != null && previous != raw && _isJsonObject(previous)) {
            await txn.insert(
              'app_state_backup',
              {'id': 1, 'json': previous, 'updated_at': now},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }

      await txn.insert(
        'app_state',
        {'id': 1, 'json': raw, 'updated_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _rebuildIndex(txn, Map<String, dynamic>.from(decoded));
      await txn.insert(
        'metadata',
        {'key': 'schema', 'value': 'v0.4.0'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> _rebuildIndex(
    Transaction txn,
    Map<String, dynamic> root,
  ) async {
    await txn.delete('finance_index');
    final batch = txn.batch();

    void addList(String kind, String key, {String accountKey = 'account'}) {
      final rawList = root[key];
      if (rawList is! List) return;
      for (final value in rawList) {
        if (value is! Map) continue;
        final item = Map<String, dynamic>.from(value);
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) continue;
        final date = DateTime.tryParse(item['date']?.toString() ?? '');
        batch.insert(
          'finance_index',
          {
            'kind': kind,
            'id': id,
            'type': item['type']?.toString(),
            'title': item['title']?.toString(),
            'category': item['category']?.toString(),
            'amount': (item['amount'] as num?)?.toDouble(),
            'date_ms': date?.millisecondsSinceEpoch,
            'account': item[accountKey]?.toString(),
            'json': jsonEncode(item),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    addList('transaction', 'transactions');
    addList('planned', 'planned', accountKey: 'sourceName');
    await batch.commit(noResult: true);
  }

  Future<int> indexedRowCount() async {
    final db = await _database();
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM finance_index');
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<String?> databasePath() async {
    try {
      final db = await _database();
      return db.path;
    } catch (error) {
      debugPrint('Finora SQLite: não foi possível obter o caminho: $error');
      return null;
    }
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null && db.isOpen) await db.close();
  }
}
