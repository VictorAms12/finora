import 'package:shared_preferences/shared_preferences.dart';

import 'intelligence_engine.dart';
import 'notification_service.dart';
import 'store.dart';

class IntelligenceNotificationService {
  IntelligenceNotificationService._();

  static const _lastDigestKey = 'finora_intelligence_last_digest_day';
  static const _engine = FinoraIntelligenceEngine();

  static Future<void> maybeNotify(FinanceStore store) async {
    if (!store.data.notificationsEnabled) return;

    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_lastDigestKey) == dayKey) return;

    final report = _engine.analyze(store, now: now);
    final important = report.insights
        .where((item) => item.severity != IntelligenceSeverity.info)
        .toList(growable: false);
    if (important.isEmpty) return;

    final first = important.first;
    final extra = important.length > 1
        ? ' +${important.length - 1} alerta${important.length - 1 == 1 ? '' : 's'}'
        : '';
    try {
      await NotificationService.showSmartInsight(
        title: 'Finora · atenção financeira',
        body: '${first.title}. ${first.message}$extra',
      );
      await prefs.setString(_lastDigestKey, dayKey);
    } catch (_) {
      // O app continua funcional mesmo quando o SO não entrega notificações.
    }
  }
}