import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static const int dailyReminderId = 3505;
  static const int testNotificationId = 3506;

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

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

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: _darwinDetails,
    macOS: _darwinDetails,
  );

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
    await plugin.initialize(settings: settings);
  }

  static Future<bool> requestPermissions() async {
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
    await plugin.cancel(id: dailyReminderId);
    if (!enabled) return;

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

  static Future<void> showTest() async {
    await plugin.show(
      id: testNotificationId,
      title: 'Finora',
      body: 'Notificações financeiras ativadas com sucesso.',
      notificationDetails: _details,
      payload: 'test',
    );
  }
}
