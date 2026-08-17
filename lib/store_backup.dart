part of 'store.dart';

extension FinanceStoreBackup on FinanceStore {
  static const _backupPrefix = 'FINORA-BACKUP-1:';

  String exportBackupText() {
    final envelope = <String, dynamic>{
      'format': 'finora-backup',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data.toJson(),
    };
    final json = jsonEncode(envelope);
    return '$_backupPrefix${base64Url.encode(utf8.encode(json))}';
  }

  Future<bool> restoreBackupText(String input) async {
    try {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return false;

      dynamic decoded;
      if (trimmed.startsWith(_backupPrefix)) {
        final payload = trimmed.substring(_backupPrefix.length);
        decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      } else {
        decoded = jsonDecode(trimmed);
      }

      if (decoded is! Map) return false;
      final map = Map<String, dynamic>.from(decoded);
      final rawData = map['format'] == 'finora-backup' ? map['data'] : map;
      if (rawData is! Map) return false;

      final restored = FinanceData.fromJson(
        Map<String, dynamic>.from(rawData),
      );

      data = restored;
      final now = DateTime.now();
      selectedMonth = DateTime(now.year, now.month);
      _ensureMonthlyTracking();
      await _save();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
