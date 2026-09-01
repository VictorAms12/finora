from pathlib import Path
import re


def load(path):
    return Path(path).read_text(encoding='utf-8')


def save(path, text):
    Path(path).write_text(text, encoding='utf-8')


def replace(path, old, new, count=1):
    text = load(path)
    actual = text.count(old)
    if actual != count:
        raise RuntimeError(f'{path}: expected {count} occurrences, found {actual}: {old[:80]!r}')
    save(path, text.replace(old, new, count))


def replace_all(path, old, new, minimum=1):
    text = load(path)
    actual = text.count(old)
    if actual < minimum:
        raise RuntimeError(f'{path}: expected at least {minimum} occurrences, found {actual}')
    save(path, text.replace(old, new))


def regex(path, pattern, replacement, count=1, flags=0):
    text = load(path)
    updated, actual = re.subn(pattern, replacement, text, count=count, flags=flags)
    if actual != count:
        raise RuntimeError(f'{path}: regex expected {count}, found {actual}: {pattern[:100]!r}')
    save(path, updated)


# Version and centralized display version.
replace('pubspec.yaml', 'version: 0.4.4+16', 'version: 0.4.5+17')
Path('lib/app_info.dart').write_text("const finoraVersion = '0.4.5';\n", encoding='utf-8')

# Transaction recurrence identity survives postpone/edit/delete and old backups remain valid.
replace(
    'lib/models.dart',
    '  String? recurrenceId;\n  String? installmentId;',
    '  String? recurrenceId;\n  DateTime? recurrenceDate;\n  String? installmentId;',
)
replace(
    'lib/models.dart',
    '    this.recurrenceId,\n    this.installmentId,',
    '    this.recurrenceId,\n    this.recurrenceDate,\n    this.installmentId,',
)
replace(
    'lib/models.dart',
    "        'recurrenceId': recurrenceId,\n        'installmentId': installmentId,",
    "        'recurrenceId': recurrenceId,\n        'recurrenceDate': recurrenceDate?.toIso8601String(),\n        'installmentId': installmentId,",
)
replace(
    'lib/models.dart',
    "        recurrenceId: j['recurrenceId'] as String?,\n        installmentId: j['installmentId'] as String?,",
    "        recurrenceId: j['recurrenceId'] as String?,\n        recurrenceDate:\n            DateTime.tryParse(j['recurrenceDate'] as String? ?? ''),\n        installmentId: j['installmentId'] as String?,",
)

# One serialization per logical commit; subclasses receive exactly the persisted raw state.
replace(
    'lib/store.dart',
    '  void commit() {\n    _invalidateCaches();\n    _ensureMonthlyTracking();\n    _queueSave(data.encode());\n    notifyListeners();\n  }',
    '  @protected\n  void onStateCommitted(String raw) {}\n\n  void commit() {\n    _invalidateCaches();\n    _ensureMonthlyTracking();\n    final raw = data.encode();\n    _queueSave(raw);\n    onStateCommitted(raw);\n    notifyListeners();\n  }',
)

# “Available” must reflect real commitments, not an arbitrary R$200 per goal.
regex(
    'lib/store.dart',
    r"  double get availableToSpend \{\n    final now = DateTime\.now\(\);\n    final receivable = cashPlannedReceivableForMonth\(now\);\n    final payable = cashPlannedPayableForMonth\(now\);\n    return \(cashBalance \+ receivable - payable - suggestedGoalContribution\)\n        \.clamp\(0\.0, double\.infinity\)\n        \.toDouble\(\);\n  \}",
    "  double get cashAfterCommitments {\n    final now = DateTime.now();\n    return cashBalance +\n        cashPlannedReceivableForMonth(now) -\n        cashPlannedPayableForMonth(now);\n  }\n\n  double get currentCashShortfall =>\n      (-cashAfterCommitments).clamp(0.0, double.infinity).toDouble();\n\n  double get availableToSpend =>\n      cashAfterCommitments.clamp(0.0, double.infinity).toDouble();",
)

# A single authoritative amount for invoice display/current manual opening balance.
replace(
    'lib/store.dart',
    "  double invoiceOutstandingForMonth(String cardId, DateTime month) =>\n      (invoiceTotalForMonth(cardId, month) - invoicePaidForMonth(cardId, month))\n          .clamp(0.0, double.infinity)\n          .toDouble();",
    "  double invoiceOutstandingForMonth(String cardId, DateTime month) =>\n      (invoiceTotalForMonth(cardId, month) - invoicePaidForMonth(cardId, month))\n          .clamp(0.0, double.infinity)\n          .toDouble();\n\n  double invoiceDisplayOutstandingForMonth(String cardId, DateTime month) {\n    var amount = invoiceOutstandingForMonth(cardId, month);\n    if (sameMonth(month, DateTime.now())) {\n      amount += manualCardOutstanding(cardId);\n    }\n    return amount;\n  }",
)

# Planning uses same factual available amount.
regex(
    'lib/store_planning.dart',
    r"  double get currentAvailableToSpend \{.*?\n  \}\n\n  double get currentAvailablePerDay",
    "  double get currentAvailableToSpend => availableToSpend;\n\n  double get currentAvailablePerDay",
    flags=re.S,
)
replace(
    'lib/store_planning.dart',
    "      data.transactions.any((tx) =>\n          tx.recurrenceId == rule.id && sameDay(tx.date, occurrence));",
    "      data.transactions.any((tx) =>\n          tx.recurrenceId == rule.id &&\n          sameDay(tx.recurrenceDate ?? tx.date, occurrence));",
)
replace_all(
    'lib/store_planning.dart',
    '        recurrenceId: id,\n      ));',
    '        recurrenceId: id,\n        recurrenceDate: startDate,\n      ));',
    minimum=1,
)
# Salary uses firstDate, not startDate.
text = load('lib/store_planning.dart')
text = text.replace('recurrenceDate: startDate,\n      ));\n    }\n    _materializeRecurringFuture(rule);',
                    'recurrenceDate: firstDate,\n      ));\n    }\n    _materializeRecurringFuture(rule);', 1)
save('lib/store_planning.dart', text)
replace(
    'lib/store_planning.dart',
    '      recurrenceId: item.recurrenceId,\n      installmentId: item.installmentId,',
    '      recurrenceId: item.recurrenceId,\n      recurrenceDate:\n          item.recurrenceId == null ? null : item.canonicalRecurrenceDate,\n      installmentId: item.installmentId,',
)

# Future conversion carries canonical recurrence identity.
replace(
    'lib/store_transactions.dart',
    '      recurrenceDate: item.recurrenceId == null ? null : item.date,',
    '      recurrenceDate: item.recurrenceDate ??\n          (item.recurrenceId == null ? null : item.date),',
)
replace(
    'lib/store_transactions.dart',
    '  void addTransaction(TransactionItem item) {\n    if (_addTransactionInternal(item)) commit();\n  }',
    '  bool addTransaction(TransactionItem item) {\n    if (!_addTransactionInternal(item)) return false;\n    commit();\n    return true;\n  }',
)
replace(
    'lib/store_transactions.dart',
    '  void updateTransaction(TransactionItem before, TransactionItem after) {\n    final index = data.transactions.indexWhere((e) => e.id == before.id);\n    if (index == -1 || !isValidAmount(after.amount)) return;\n\n    _prepareCardInvoice(after);',
    '  bool updateTransaction(TransactionItem before, TransactionItem after) {\n    final index = data.transactions.indexWhere((e) => e.id == before.id);\n    if (index == -1 || !isValidAmount(after.amount)) return false;\n\n    if (after.recurrenceId != null && after.recurrenceDate == null) {\n      after.recurrenceDate = before.recurrenceDate ?? before.date;\n    }\n    if (after.paymentKind == PaymentKind.card &&\n        after.type == TransactionType.expense &&\n        after.cardId == before.cardId &&\n        after.invoiceMonth == null &&\n        before.invoiceMonth != null) {\n      after.invoiceMonth = before.invoiceMonth;\n    }\n    _prepareCardInvoice(after);',
)
replace(
    'lib/store_transactions.dart',
    '    if (rebuildFrom != null) rebuildSnapshotsFrom(rebuildFrom);\n    commit();\n  }\n\n  void deleteTransaction(TransactionItem item) {',
    '    if (rebuildFrom != null) rebuildSnapshotsFrom(rebuildFrom);\n    commit();\n    return true;\n  }\n\n  void deleteTransaction(TransactionItem item) {',
)
replace(
    'lib/store_transactions.dart',
    "  void deleteTransaction(TransactionItem item) {\n    final exists = data.transactions.any((e) => e.id == item.id);\n    if (!exists) return;\n\n    _applyTransactionEffect(item, reverse: true);\n    data.transactions.removeWhere((e) => e.id == item.id);\n    final rebuildFrom = _earliestPastMonth(item.date);\n    if (rebuildFrom != null) rebuildSnapshotsFrom(rebuildFrom);\n    commit();\n  }",
    "  void deleteTransaction(TransactionItem item) {\n    final exists = data.transactions.any((e) => e.id == item.id);\n    if (!exists) return;\n\n    if (item.recurrenceId != null &&\n        data.recurringRules.any((rule) => rule.id == item.recurrenceId)) {\n      final canonical = item.recurrenceDate ?? item.date;\n      PlannedItem? occurrence;\n      for (final planned in data.planned) {\n        if (planned.recurrenceId == item.recurrenceId &&\n            sameDay(planned.canonicalRecurrenceDate, canonical)) {\n          occurrence = planned;\n          break;\n        }\n      }\n      if (occurrence != null) {\n        occurrence.status = PlannedStatus.skipped;\n      } else {\n        final tombstone = _plannedFromTransaction(item)\n          ..date = canonical\n          ..recurrenceDate = canonical\n          ..status = PlannedStatus.skipped;\n        data.planned.add(tombstone);\n      }\n    }\n\n    if (item.installmentId != null &&\n        data.installmentPlans.any((plan) => plan.id == item.installmentId)) {\n      PlannedItem? installment;\n      for (final planned in data.planned) {\n        if (planned.installmentId == item.installmentId &&\n            planned.installmentNumber == item.installmentNumber) {\n          installment = planned;\n          break;\n        }\n      }\n      if (installment != null) {\n        if (installment.status == PlannedStatus.settled) {\n          installment.status = PlannedStatus.planned;\n        }\n      } else {\n        data.planned.add(_plannedFromTransaction(item));\n      }\n    }\n\n    _applyTransactionEffect(item, reverse: true);\n    data.transactions.removeWhere((e) => e.id == item.id);\n    final rebuildFrom = _earliestPastMonth(item.date);\n    if (rebuildFrom != null) rebuildSnapshotsFrom(rebuildFrom);\n    commit();\n  }",
)

# Goals receive the same no-data-loss semantics fixed for reserves.
replace_all(
    'lib/store_entities.dart',
    'saved.clamp(0.0, target).toDouble()',
    'saved.clamp(0.0, double.infinity).toDouble()',
    minimum=2,
)
replace(
    'lib/store_entities.dart',
    '    item.saved = (item.saved + value).clamp(0.0, item.target).toDouble();',
    '    item.saved = (item.saved + value).clamp(0.0, double.infinity).toDouble();',
)

# Account names used by retained history cannot be reused after deleting an account.
replace(
    'lib/store_entities.dart',
    "  bool accountNameExists(String name, {String? exceptId}) {\n    final normalized = _normalizedName(name);\n    if (normalized.isEmpty) return false;\n    return data.accounts.any((account) =>\n        account.id != exceptId && _normalizedName(account.name) == normalized);\n  }",
    "  bool accountNameExists(String name, {String? exceptId}) {\n    final normalized = _normalizedName(name);\n    if (normalized.isEmpty) return false;\n    return data.accounts.any((account) =>\n        account.id != exceptId && _normalizedName(account.name) == normalized);\n  }\n\n  bool _historicalAccountNameUsed(String name) {\n    final normalized = _normalizedName(name);\n    for (final tx in data.transactions) {\n      if (tx.type == TransactionType.transfer) {\n        final pair = transferAccounts(tx);\n        if (pair != null && pair.any((value) => _normalizedName(value) == normalized)) {\n          return true;\n        }\n      } else if (_normalizedName(tx.account) == normalized) {\n        return true;\n      }\n    }\n    return false;\n  }",
)
replace(
    'lib/store_entities.dart',
    '    if (clean.isEmpty || accountNameExists(clean) || !balance.isFinite) {',
    '    if (clean.isEmpty ||\n        accountNameExists(clean) ||\n        _historicalAccountNameUsed(clean) ||\n        !balance.isFinite) {',
)

# Category type change cannot rewrite existing financial history into the opposite type.
replace(
    'lib/store_entities.dart',
    '    final oldName = item.name;\n    item.name = clean;\n    item.income = income;',
    "    final oldName = item.name;\n    if (income != item.income) {\n      final referenced = data.transactions.any((e) => e.category == oldName) ||\n          data.planned.any((e) => e.category == oldName) ||\n          data.recurringRules.any((e) => e.category == oldName) ||\n          data.installmentPlans.any((e) => e.category == oldName) ||\n          data.budgets.any((e) => e.category == oldName);\n      if (referenced) return false;\n    }\n    item.name = clean;\n    item.income = income;",
)
replace(
    'lib/store_entities.dart',
    '  void deleteCategory(String id) {\n    data.categories.removeWhere((e) => e.id == id);\n    commit();\n  }',
    "  bool deleteCategory(String id) {\n    final index = data.categories.indexWhere((e) => e.id == id);\n    if (index == -1) return false;\n    final name = data.categories[index].name;\n    final inUse = data.budgets.any((e) => e.category == name) ||\n        data.planned.any((e) =>\n            e.status == PlannedStatus.planned && e.category == name) ||\n        data.recurringRules.any((e) => e.active && e.category == name);\n    if (inUse) return false;\n    data.categories.removeAt(index);\n    commit();\n    return true;\n  }",
)

# Account/card deletion must not orphan future commitments.
replace(
    'lib/store_entities.dart',
    "  void deleteAccount(String id) {\n    final index = data.accounts.indexWhere((e) => e.id == id);\n    if (index == -1) return;\n    final removedName = data.accounts[index].name;\n    data.accounts.removeAt(index);\n\n    for (final card in data.cards.where((e) => e.defaultAccountName == removedName)) {\n      card.defaultAccountName = '';\n    }\n    commit();\n  }",
    "  bool deleteAccount(String id) {\n    final index = data.accounts.indexWhere((e) => e.id == id);\n    if (index == -1) return false;\n    final removedName = data.accounts[index].name;\n    final hasPending = data.planned.any((item) =>\n        item.status == PlannedStatus.planned &&\n        (item.sourceName == removedName || item.destinationName == removedName));\n    final hasRecurring = data.recurringRules.any((rule) =>\n        rule.active &&\n        rule.paymentKind == PaymentKind.account &&\n        rule.sourceName == removedName);\n    if (hasPending || hasRecurring) return false;\n\n    data.accounts.removeAt(index);\n    for (final card in data.cards.where((e) => e.defaultAccountName == removedName)) {\n      card.defaultAccountName = '';\n    }\n    commit();\n    return true;\n  }",
)

# Card edits preserve historical competencies and cannot hide tracked debt.
regex(
    'lib/store_entities.dart',
    r"  bool updateCard\(\n    CardItem item,.*?\n  \}\n\n  void deleteCard\(String id\) \{\n    data\.cards\.removeWhere\(\(e\) => e\.id == id\);\n    commit\(\);\n  \}",
    """  bool updateCard(
    CardItem item,
    String name,
    double limit,
    double used,
    int closeDay,
    int dueDay,
    String defaultAccountName,
  ) {
    final clean = name.trim();
    if (clean.isEmpty || !isValidAmount(limit) || !used.isFinite) return false;
    final tracked = trackedCardOutstanding(item.id);
    if (used < -0.005 || used + 0.005 < tracked) return false;

    final oldName = item.name;
    item.name = clean;
    item.limit = limit;
    item.used = used.clamp(0.0, double.infinity).toDouble();
    item.closeDay = closeDay.clamp(1, 31);
    item.dueDay = dueDay.clamp(1, 31);
    item.defaultAccountName = defaultAccountName;

    // Faturas históricas são fatos. Alterar fechamento/vencimento só afeta
    // compromissos ainda pendentes; compras já realizadas mantêm competência.
    for (final tx in data.transactions.where((e) =>
        e.paymentKind == PaymentKind.card && e.cardId == item.id)) {
      tx.account = clean;
    }
    for (final tx in data.transactions.where((e) =>
        e.type == TransactionType.transfer &&
        e.cardId == item.id &&
        e.title.startsWith('Pagamento fatura'))) {
      final pair = transferAccounts(tx);
      if (pair != null) tx.account = '${pair[0]} → $clean';
      tx.title = 'Pagamento fatura $clean';
    }
    for (final planned in data.planned.where((e) => e.cardId == item.id)) {
      planned.sourceName = clean;
      if (planned.status == PlannedStatus.planned) {
        planned.invoiceMonth = invoiceMonthForPurchase(item, planned.date);
      }
    }
    for (final rule in data.recurringRules.where((e) => e.cardId == item.id)) {
      rule.sourceName = clean;
    }
    for (final plan in data.installmentPlans.where((e) => e.cardId == item.id)) {
      plan.sourceName = clean;
    }
    for (final tx in data.transactions.where((e) => e.account == oldName)) {
      if (tx.paymentKind == PaymentKind.card) tx.account = clean;
    }
    commit();
    return true;
  }

  bool deleteCard(String id) {
    final exists = data.cards.any((e) => e.id == id);
    if (!exists) return false;
    final hasPending = data.planned.any((item) =>
        item.status == PlannedStatus.planned && item.cardId == id);
    final hasRecurring =
        data.recurringRules.any((rule) => rule.active && rule.cardId == id);
    if (hasPending || hasRecurring) return false;
    data.cards.removeWhere((e) => e.id == id);
    commit();
    return true;
  }""",
    flags=re.S,
)

# SQLite failure marker prevents stale DB state from overwriting newer legacy state on restart.
replace(
    'lib/sqlite_store.dart',
    "  static const _legacyBackupKey = 'finora_data_v02_backup';",
    "  static const _legacyBackupKey = 'finora_data_v02_backup';\n  static const _sqliteDirtyKey = 'finora_sqlite_needs_resync';",
)
replace(
    'lib/sqlite_store.dart',
    '    String? sqlitePrimary;\n    String? sqliteBackup;\n    var databaseOpened = false;',
    "    String? sqlitePrimary;\n    String? sqliteBackup;\n    var databaseOpened = false;\n    final prefs = await SharedPreferences.getInstance();\n    final sqliteDirty = prefs.getBool(_sqliteDirtyKey) == true;",
)
replace(
    'lib/sqlite_store.dart',
    "      debugPrint('Finora SQLite: falha ao abrir banco; usando legado: $error');\n      debugPrintStack(stackTrace: stackTrace);",
    "      await prefs.setBool(_sqliteDirtyKey, true);\n      debugPrint('Finora SQLite: falha ao abrir banco; usando legado: $error');\n      debugPrintStack(stackTrace: stackTrace);",
)
replace(
    'lib/sqlite_store.dart',
    '    if (databaseData != null && databaseRaw != null) {\n      await _mirrorToLegacy(databaseRaw);\n    }',
    '    if (!sqliteDirty && databaseData != null && databaseRaw != null) {\n      await _mirrorToLegacy(databaseRaw);\n    }',
)
replace(
    'lib/sqlite_store.dart',
    "        _lastSqliteRaw = normalized;\n        _sqliteAvailable = true;\n        _storageError = null;",
    "        _lastSqliteRaw = normalized;\n        _sqliteAvailable = true;\n        _storageError = null;\n        await prefs.setBool(_sqliteDirtyKey, false);",
)
replace(
    'lib/sqlite_store.dart',
    "        _sqliteAvailable = false;\n        _storageError = error.toString();\n        debugPrint('Finora SQLite: falha na migração inicial: $error');",
    "        _sqliteAvailable = false;\n        _storageError = error.toString();\n        await prefs.setBool(_sqliteDirtyKey, true);\n        debugPrint('Finora SQLite: falha na migração inicial: $error');",
)
regex(
    'lib/sqlite_store.dart',
    r"  void _queueSqliteSave\(String raw\) \{.*?\n  \}\n\n  @override\n  void commit\(\) \{\n    super\.commit\(\);\n    _queueSqliteSave\(data\.encode\(\)\);\n  \}",
    """  void _queueSqliteSave(String raw) {
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
  void onStateCommitted(String raw) => _queueSqliteSave(raw);""",
    flags=re.S,
)

# Avoid rebuilding the entire SQLite query index for theme/reserve/settings-only commits.
replace(
    'lib/local_database.dart',
    '    final db = await _database();\n    final now = DateTime.now().millisecondsSinceEpoch;\n    await db.transaction((txn) async {',
    "    final root = Map<String, dynamic>.from(decoded);\n    final indexSignature = _financeIndexSignature(root);\n    final db = await _database();\n    final now = DateTime.now().millisecondsSinceEpoch;\n    await db.transaction((txn) async {",
)
replace(
    'lib/local_database.dart',
    "      await _rebuildIndex(txn, Map<String, dynamic>.from(decoded));\n      await txn.insert(\n        'metadata',\n        {'key': 'schema', 'value': 'v0.4.0'},",
    "      final signatureRows = await txn.query(\n        'metadata',\n        columns: ['value'],\n        where: 'key = ?',\n        whereArgs: ['finance_index_signature'],\n      );\n      final previousSignature = signatureRows.isEmpty\n          ? null\n          : signatureRows.first['value']?.toString();\n      if (previousSignature != indexSignature) {\n        await _rebuildIndex(txn, root);\n        await txn.insert(\n          'metadata',\n          {'key': 'finance_index_signature', 'value': indexSignature},\n          conflictAlgorithm: ConflictAlgorithm.replace,\n        );\n      }\n      await txn.insert(\n        'metadata',\n        {'key': 'schema', 'value': 'v0.4.5'},",
)
replace(
    'lib/local_database.dart',
    '  Future<void> _rebuildIndex(\n',
    "  String _financeIndexSignature(Map<String, dynamic> root) {\n    final raw = jsonEncode([root['transactions'] ?? const [], root['planned'] ?? const []]);\n    var hash = 0xcbf29ce484222325;\n    for (final unit in raw.codeUnits) {\n      hash ^= unit;\n      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;\n    }\n    return hash.toRadixString(16);\n  }\n\n  Future<void> _rebuildIndex(\n",
)

# Shared number parser handles pt-BR thousands/decimal input and rejects non-finite values.
replace(
    'lib/ui/common.dart',
    'String money(BuildContext context, double value) {',
    "double? parseNumberInput(String raw) {\n  var value = raw.trim().replaceAll('R\\$', '').replaceAll(' ', '').replaceAll('\\u00a0', '');\n  if (value.isEmpty) return null;\n  final comma = value.lastIndexOf(',');\n  final dot = value.lastIndexOf('.');\n  if (comma >= 0 && dot >= 0) {\n    if (comma > dot) {\n      value = value.replaceAll('.', '').replaceAll(',', '.');\n    } else {\n      value = value.replaceAll(',', '');\n    }\n  } else if (comma >= 0) {\n    value = value.replaceAll(',', '.');\n  } else if (value.split('.').length > 2) {\n    final last = value.lastIndexOf('.');\n    value = value.substring(0, last).replaceAll('.', '') + value.substring(last);\n  }\n  final parsed = double.tryParse(value);\n  return parsed != null && parsed.isFinite ? parsed : null;\n}\n\nString money(BuildContext context, double value) {",
)

# Route every reserve entry point through the corrected v0.4.4 editor.
replace(
    'lib/ui/forms.dart',
    "import 'forms_v035.dart' as v035;",
    "import 'forms_v035.dart' as v035;\nimport 'reserve_forms.dart' as reserve_ui;",
)
replace(
    'lib/ui/forms.dart',
    "export 'forms_v035.dart'\n    hide showPlannedDetails, showQuickActions, showPlannedForm;",
    "export 'forms_v035.dart'\n    hide showPlannedDetails, showQuickActions, showPlannedForm, showReserveForm;\n\nFuture<void> showReserveForm(BuildContext context, {ReserveItem? editing}) =>\n    reserve_ui.showReserveEditor(context, editing: editing);",
)
replace(
    'lib/ui/forms.dart',
    '                      v035.showReserveForm(context);',
    '                      showReserveForm(context);',
)

# Critical form fixes: pt-BR parsing, preserve historical invoice/recurrence identity, respect store failures.
text = load('lib/ui/forms_v035.dart')
text = re.sub(
    r"double\.tryParse\(\s*([A-Za-z_][A-Za-z0-9_]*)\.text\.replaceAll\(',', '\.'\),?\s*\)\s*\?\?\s*0",
    r"parseNumberInput(\1.text) ?? 0",
    text,
)
text = text.replace(
    "                          recurrenceId: editing.recurrenceId,\n                          installmentId: editing.installmentId,",
    "                          recurrenceId: editing.recurrenceId,\n                          recurrenceDate: editing.recurrenceDate,\n                          installmentId: editing.installmentId,\n                          invoiceMonth: editing.invoiceMonth,",
)
old_flow = """                    if (editing != null) {
                      store.updateTransaction(
                        editing,
                        TransactionItem("""
if old_flow not in text:
    raise RuntimeError('transaction edit flow marker missing')
text = text.replace(old_flow, """                    bool savedOk;
                    if (editing != null) {
                      savedOk = store.updateTransaction(
                        editing,
                        TransactionItem(""", 1)
text = text.replace(
    """                      );
                    } else if (installment && type == TransactionType.expense) {
                      final count = int.tryParse(installmentsController.text) ?? 1;
                      if (count < 2) return;
                      store.addInstallment(""",
    """                      );
                    } else if (installment && type == TransactionType.expense) {
                      final count = int.tryParse(installmentsController.text) ?? 1;
                      if (count < 2) return;
                      savedOk = store.addInstallment(""",
    1,
)
text = text.replace('                      store.addRecurring(\n', '                      savedOk = store.addRecurring(\n', 1)
text = text.replace('                      store.addTransaction(TransactionItem(\n', '                      savedOk = store.addTransaction(TransactionItem(\n', 1)
text = text.replace(
    """                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(editing == null ? 'Lançamento salvo' : 'Lançamento atualizado')),
                    );""",
    """                    if (!savedOk) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Não foi possível salvar. Confira valor, origem e dados do lançamento.')),
                      );
                      return;
                    }
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(editing == null ? 'Lançamento salvo' : 'Lançamento atualizado')),
                    );""",
    1,
)
# Planned settlement only closes on success.
text = text.replace(
    """                  onPressed: () {
                    context.read<FinanceStore>().settlePlanned(item);
                    Navigator.pop(sheetContext);
                  },""",
    """                  onPressed: () {
                    final ok = context.read<FinanceStore>().settlePlanned(item);
                    if (ok) {
                      Navigator.pop(sheetContext);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Não foi possível realizar este previsto. Verifique a conta ou o cartão vinculado.')),
                      );
                    }
                  },""",
    1,
)
# Transfers/invoice payments can be deleted/reversed; editing remains disabled for transfers.
pattern = re.compile(r"            if \(item\.type != TransactionType\.transfer\) \.\.\.\[\n              const SizedBox\(height: 12\),\n              Row\(\n                children: \[.*?\n              \),\n            \],", re.S)
match = pattern.search(text)
if not match:
    raise RuntimeError('transaction detail action block missing')
replacement = """            const SizedBox(height: 12),
            Row(
              children: [
                if (item.type != TransactionType.transfer) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        showTransactionForm(context, item.type, editing: item);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await confirmAction(
                        context,
                        'Excluir lançamento?',
                        item.type == TransactionType.transfer
                            ? 'Os saldos envolvidos serão recompostos automaticamente.'
                            : 'O saldo da conta ou a fatura será ajustado automaticamente.',
                      );
                      if (!ok || !context.mounted) return;
                      context.read<FinanceStore>().deleteTransaction(item);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Excluir'),
                  ),
                ),
              ],
            ),"""
text = text[:match.start()] + replacement + text[match.end():]
# Critical entity editors only close when the store accepts the change.
text = text.replace(
    "if (editing == null) { store.addAccount(name.text.trim(), bv, type: type); } else { store.updateAccount(editing, name.text.trim(), type, bv); } Navigator.pop(sheetContext);",
    "final ok = editing == null ? store.addAccount(name.text.trim(), bv, type: type) : store.updateAccount(editing, name.text.trim(), type, bv); if (!ok) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar a conta. O nome pode estar em uso ou reservado pelo histórico.'))); return; } Navigator.pop(sheetContext);",
    1,
)
text = text.replace(
    "if (editing == null) { store.addCard(name.text.trim(), lv, uv, cv, dv, defaultAccountName: defaultAccount); } else { store.updateCard(editing, name.text.trim(), lv, uv, cv, dv, defaultAccount); } Navigator.pop(sheetContext);",
    "final ok = editing == null ? store.addCard(name.text.trim(), lv, uv, cv, dv, defaultAccountName: defaultAccount) : store.updateCard(editing, name.text.trim(), lv, uv, cv, dv, defaultAccount); if (!ok) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar o cartão. O saldo informado não pode ficar abaixo das compras ainda pendentes.'))); return; } Navigator.pop(sheetContext);",
    1,
)
text = text.replace(
    "if (editing == null) { store.addCategory(name.text.trim(), income); } else { store.updateCategory(editing, name.text.trim(), income); } Navigator.pop(sheetContext);",
    "final ok = editing == null ? store.addCategory(name.text.trim(), income) : store.updateCategory(editing, name.text.trim(), income); if (!ok) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar a categoria. Categorias em uso não podem trocar entre receita e despesa.'))); return; } Navigator.pop(sheetContext);",
    1,
)
save('lib/ui/forms_v035.dart', text)

# Account/card deletion feedback and authoritative invoice display.
replace(
    'lib/ui/accounts.dart',
    "                                if (ok) store.deleteCard(card.id);",
    "                                if (ok && !store.deleteCard(card.id) && context.mounted) {\n                                  ScaffoldMessenger.of(context).showSnackBar(\n                                    const SnackBar(content: Text('Este cartão ainda possui previsões ou recorrências ativas. Resolva esses vínculos antes de excluí-lo.')),\n                                  );\n                                }",
)
replace(
    'lib/ui/accounts.dart',
    "                        context.read<FinanceStore>().deleteAccount(account.id);\n                        if (sheetContext.mounted) Navigator.pop(sheetContext);",
    "                        final deleted = context.read<FinanceStore>().deleteAccount(account.id);\n                        if (!deleted) {\n                          ScaffoldMessenger.of(context).showSnackBar(\n                            const SnackBar(content: Text('Esta conta ainda é usada por previsões ou recorrências ativas.')),\n                          );\n                          return;\n                        }\n                        if (sheetContext.mounted) Navigator.pop(sheetContext);",
)
regex(
    'lib/ui/accounts.dart',
    r"    var outstanding =\n        store\.invoiceOutstandingForMonth\(card\.id, store\.selectedMonth\);\n    if \(store\.selectedIsCurrent\) \{\n      outstanding \+= store\.manualCardOutstanding\(card\.id\);\n    \}",
    "    final outstanding =\n        store.invoiceDisplayOutstandingForMonth(card.id, store.selectedMonth);",
)

# Custom category deletion must report active dependencies.
replace(
    'lib/ui/categories_settings_v035.dart',
    '                            if (ok) store.deleteCategory(item.id);',
    "                            if (ok && !store.deleteCategory(item.id) && context.mounted) {\n                              ScaffoldMessenger.of(context).showSnackBar(\n                                const SnackBar(content: Text('Esta categoria ainda é usada por orçamento, previsão ou recorrência ativa.')),\n                              );\n                            }",
)

# Dashboard past-month semantics and commitment shortfall visibility.
replace(
    'lib/ui/dashboard.dart',
    "    final primaryLabel = store.selectedIsFuture\n        ? 'SALDO PROJETADO'\n        : store.selectedIsPast\n            ? 'FECHAMENTO DO MÊS'\n            : 'PATRIMÔNIO';",
    "    final primaryLabel = store.selectedIsFuture\n        ? 'SALDO PROJETADO'\n        : store.selectedIsPast\n            ? (snapshot == null ? 'RESULTADO DO MÊS' : 'FECHAMENTO DO MÊS')\n            : 'PATRIMÔNIO';",
)
replace(
    'lib/ui/dashboard.dart',
    "                            : store.selectedIsPast\n                                ? 'Detalhes do fechamento mensal'\n                                : 'Disponível para gastar',",
    "                            : store.selectedIsPast\n                                ? (snapshot == null\n                                    ? 'Resultado registrado no mês'\n                                    : 'Detalhes do fechamento mensal')\n                                : 'Disponível para gastar',",
)
# Add a real deficit alert before overdue alert.
marker = "          if (store.selectedIsCurrent && store.overduePlannedCount > 0) ...["
if marker not in load('lib/ui/dashboard.dart'):
    raise RuntimeError('dashboard deficit insertion marker missing')
replace(
    'lib/ui/dashboard.dart',
    marker,
    """          if (store.selectedIsCurrent && store.currentCashShortfall > 0) ...[
            const SizedBox(height: 10),
            SurfaceCard(
              borderColor: FinoraColors.expense.withValues(alpha: .30),
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: FinoraColors.expense),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Faltam ${money(context, store.currentCashShortfall)} para cobrir os compromissos já previstos.',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (store.selectedIsCurrent && store.overduePlannedCount > 0) ...[""",
)

# Available breakdown: goals are recommendation, not an invented obligation.
text = load('lib/ui/forms_v035.dart')
text = text.replace(
    """              breakdownRow(context, 'Contas, parcelas e faturas', store.selectedCashPlannedPayable, FinoraColors.expense),
              breakdownRow(context, 'Reserva sugerida para metas', store.suggestedGoalContribution, FinoraColors.goal),
              const Divider(height: 24),
              breakdownTotal(context, 'Disponível', store.availableToSpend, FinoraColors.income),""",
    """              breakdownRow(context, 'Contas, parcelas e faturas', store.selectedCashPlannedPayable, FinoraColors.expense),
              const Divider(height: 24),
              breakdownTotal(context, 'Disponível', store.availableToSpend, FinoraColors.income),
              if (store.currentCashShortfall > 0) ...[
                const SizedBox(height: 10),
                Text('Déficit previsto: ${money(context, store.currentCashShortfall)}', style: const TextStyle(color: FinoraColors.expense, fontWeight: FontWeight.w800)),
              ],
              if (store.suggestedGoalContribution > 0) ...[
                const SizedBox(height: 10),
                Text('Sugestão opcional para metas: ${money(context, store.suggestedGoalContribution)}', style: const TextStyle(color: FinoraColors.goal, fontSize: 9.5)),
              ],""",
    1,
)
save('lib/ui/forms_v035.dart', text)

# AI uses the same authoritative calculations as the rest of the app.
replace(
    'lib/ai/finance_ai.dart',
    "    store.addTransaction(\n      TransactionItem(",
    "    return store.addTransaction(\n      TransactionItem(",
)
replace(
    'lib/ai/finance_ai.dart',
    "    );\n    return true;\n  }\n}\n\nclass FinoraAiService",
    "    );\n  }\n}\n\nclass FinoraAiService",
)
replace(
    'lib/ai/finance_ai.dart',
    "      final payable = store.plannedPayableForMonth(selected);\n      final receivable = store.plannedReceivableForMonth(selected);",
    "      final now = DateTime.now();\n      final payable = store.cashPlannedPayableForMonth(now);\n      final receivable = store.cashPlannedReceivableForMonth(now);",
)
replace(
    'lib/ai/finance_ai.dart',
    "        final invoice = store.invoiceOutstandingForMonth(card.id, selected);",
    "        final invoice =\n            store.invoiceDisplayOutstandingForMonth(card.id, DateTime.now());",
)
replace(
    'lib/ai/finance_ai.dart',
    "              'faturaAtual': store.invoiceOutstandingForMonth(e.id, selected),",
    "              'faturaAtual':\n                  store.invoiceDisplayOutstandingForMonth(e.id, selected),",
)
# Make AI-created title/note bounded and reject unreasonable model dates.
replace(
    'lib/ai/finance_ai.dart',
    "    final date = DateTime.tryParse(result['date']?.toString() ?? '') ?? DateTime.now();\n    final titleValue = result['title']?.toString().trim() ?? '';",
    "    final date = DateTime.tryParse(result['date']?.toString() ?? '') ?? DateTime.now();\n    if (date.year < 2020 || date.year > 2100) {\n      return const AiTransactionInterpretation.clarify('Qual é a data desse lançamento?');\n    }\n    final titleValue = _truncate(result['title']?.toString().trim() ?? '', 120);",
)
replace(
    'lib/ai/finance_ai.dart',
    "        note: result['note']?.toString().trim() ?? '',",
    "        note: _truncate(result['note']?.toString().trim() ?? '', 500),",
)
replace(
    'lib/ai/finance_ai.dart',
    '  String _money(double value) {',
    "  String _truncate(String value, int max) =>\n      value.length <= max ? value : value.substring(0, max).trimRight();\n\n  String _money(double value) {",
)

# Centralized version labels.
replace(
    'lib/ui/settings_v038.dart',
    "import '../notification_service.dart';",
    "import '../app_info.dart';\nimport '../notification_service.dart';",
)
replace('lib/ui/settings_v038.dart', "'Finora v0.4.0'", "'Finora v$finoraVersion'")
replace(
    'lib/ui/home_shell.dart',
    "import '../theme.dart';",
    "import '../app_info.dart';\nimport '../theme.dart';",
)
replace('lib/ui/home_shell.dart', "'Finora Desktop · v0.4.3\\nCtrl + N para novo lançamento'", "'Finora Desktop · v$finoraVersion\\nCtrl + N para novo lançamento'")

# Regression suite for the defects found in this audit.
Path('test/v045_integrity_audit_test.dart').write_text(r'''import 'dart:convert';

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
''', encoding='utf-8')

# Changelog.
text = load('CHANGELOG.md')
entry = '''## [0.4.5] - 2026-09-01\n\n### Integridade e comportamento\n- auditoria geral das regras de conta, cartão, fatura, planejamento, recorrências, parcelas, metas, SQLite e IA;\n- editar fechamento/vencimento de cartão deixa de reclassificar compras históricas em outras faturas;\n- cartões não aceitam valor usado abaixo da dívida já rastreada;\n- contas/cartões/categorias com compromissos ativos deixam de ser excluídos de forma a criar referências órfãs;\n- nomes de contas removidas permanecem reservados enquanto existirem lançamentos históricos, evitando que operações antigas alterem uma nova conta homônima;\n- apagar ocorrência recorrente realizada mantém uma marca de ignorada e impede reaparecimento;\n- apagar parcela realizada devolve a obrigação ao planejamento quando o parcelamento ainda existe;\n- metas passam a preservar valores acumulados acima do alvo, inclusive após redução da meta;\n- transferências e pagamentos de fatura podem ser excluídos pela interface e têm os efeitos revertidos;\n- realizar previsto inválido deixa de fechar a tela silenciosamente.\n\n### Cálculos e consistência\n- “Disponível para gastar” passa a considerar apenas saldo, entradas e compromissos reais; sugestão de aporte em metas deixa de ser descontada como se fosse dívida;\n- déficit de caixa previsto passa a ser exposto separadamente;\n- IA, tela de cartão e pagamento de fatura compartilham o mesmo cálculo de fatura atual;\n- meses históricos sem snapshot são identificados como resultado do mês, não como saldo final conhecido.\n\n### Persistência e desempenho\n- commits serializam o estado uma vez e reutilizam o mesmo snapshot para SQLite e espelho legado;\n- SQLite marca gravações incompletas e, após falha, prefere o espelho mais novo no próximo início antes de ressincronizar o banco;\n- índice SQLite de movimentações só é reconstruído quando transações/planejamento mudam, evitando trabalho pesado em alterações de tema, reserva ou configurações.\n\n### UX e manutenção\n- entradas numéricas passam a aceitar melhor formatos brasileiros como `1.234,56`;\n- atalhos de reserva usam o editor corrigido;\n- formulários críticos mostram falha em vez de fechar como se tivessem salvo;\n- versão exibida foi centralizada para evitar rodapés desatualizados;\n- adicionada suíte de regressão específica para os problemas encontrados na auditoria.\n\n'''
if '## [0.4.5]' not in text:
    text = text.replace('# Changelog\n\n', '# Changelog\n\n' + entry, 1)
save('CHANGELOG.md', text)

print('v0.4.5 audit patch applied')
