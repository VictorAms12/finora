import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static const int dailyReminderId = 3505;
  static const int testNotificationId = 3506;
  static const int smartInsightNotificationId = 3510;

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  static Future<void>? _initialization;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'finora_finance_reminders',
    'Lembretes financeiros',
    channelDescription: 'Lembretes de contas, parcelas e planejamento do Finora',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const DarwinNotificationDetails _darwinDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const WindowsNotificationDetails _windowsDetails =
      WindowsNotificationDetails(
    subtitle: 'Finora · Gestão financeira',
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: _darwinDetails,
    macOS: _darwinDetails,
    windows: _windowsDetails,
  );

  static Future<void> initialize() =>
      _initialization ??= _initializePlugin();

  static Future<void> _initializePlugin() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const windows = WindowsInitializationSettings(
      appName: 'Finora',
      appUserModelId: 'VictorAms12.Finora.Desktop',
      guid: '8f4ec9d1-82ab-4fb3-bcb5-5e3d76c5f036',
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      windows: windows,
    );
    await plugin.initialize(settings: settings);
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    var granted = true;

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
    }

    final ios = plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return granted;
  }

  static Future<void> setDailyReminder(bool enabled) async {
    await initialize();
    try {
      await plugin.cancel(id: dailyReminderId);
    } catch (_) {
      // Builds portáteis do Windows podem não ter identidade de pacote.
    }
    if (!enabled) return;

    if (Platform.isWindows) {
      // O backend Windows do plugin não oferece notificações periódicas.
      return;
    }

    await plugin.periodicallyShow(
      id: dailyReminderId,
      title: 'Finora · planejamento do dia',
      body: 'Confira contas, parcelas e compromissos financeiros próximos.',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'planning',
    );
  }

  static Future<void> showSmartInsight({
    required String title,
    required String body,
  }) async {
    await initialize();
    await plugin.show(
      id: smartInsightNotificationId,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: 'intelligence',
    );
  }

  static Future<void> showTest() async {
    await initialize();
    await plugin.show(
      id: testNotificationId,
      title: 'Finora',
      body: 'Notificações financeiras ativadas com sucesso.',
      notificationDetails: _details,
      payload: 'test',
    );
  }
}
