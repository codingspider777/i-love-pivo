import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:salamanca/data/models/task.dart';

/// Select at most 60 future reminders (iOS allows only 64 pending requests).
List<Task> reminderTasks(List<Task> tasks, int minutes, DateTime now) {
  final result =
      tasks
          .where(
            (t) =>
                !t.isDone &&
                t.time != null &&
                t.dueTime.subtract(Duration(minutes: minutes)).isAfter(now),
          )
          .toList()
        ..sort((a, b) => a.dueTime.compareTo(b.dueTime));
  return result.take(60).toList();
}

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _plugin;
  bool initialized = false;
  Future<void> _pending = Future.value();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> synchronize(
    List<Task> tasks, {
    required bool enabled,
    required bool sound,
    required int minutes,
  }) {
    if (!initialized) return Future.value();
    _pending = _pending.catchError((Object _) {}).then((_) async {
      await _plugin.cancelAllPendingNotifications();
      if (!enabled) return;
      for (final task in reminderTasks(tasks, minutes, DateTime.now())) {
        await _plugin.zonedSchedule(
          id: task.id,
          title: 'Напоминание о задаче',
          body: task.title,
          scheduledDate: tz.TZDateTime.from(
            task.dueTime.subtract(Duration(minutes: minutes)),
            tz.local,
          ),
          notificationDetails: NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentSound: sound,
              sound: sound ? 'default' : null,
            ),
            android: AndroidNotificationDetails(
              sound ? 'task_reminders_sound' : 'task_reminders_silent',
              'Напоминания о задачах',
              playSound: sound,
              importance: Importance.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id.toString(),
        );
      }
    });
    return _pending;
  }
}
