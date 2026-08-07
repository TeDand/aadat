import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

const _channelId = 'aadat_habits';
const _channelName = 'Habit reminders';

// Notification ID namespaces
const _kIdDailyReminder = 100;
const _kIdWeeklyReminder = 101;
const _kIdMonthlyReminder = 102;
const _kIdMilestoneBase = 200; // 200+ for milestone toasts

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  // ── Milestone (immediate) ─────────────────────────────────────────────────

  static Future<void> showMilestone(String title, String body) async {
    final id = _kIdMilestoneBase + DateTime.now().millisecondsSinceEpoch % 1000;
    await _plugin.show(id, title, body, _details);
  }

  // ── Deadline reminders (daily scheduled) ─────────────────────────────────

  /// Call this after habits are loaded or toggled.
  /// [daily] / [weekly] / [monthly] = number of incomplete habits of each type.
  static Future<void> rescheduleDeadlineReminders({
    required int daily,
    required int weekly,
    required int monthly,
  }) async {
    await _plugin.cancel(_kIdDailyReminder);
    await _plugin.cancel(_kIdWeeklyReminder);
    await _plugin.cancel(_kIdMonthlyReminder);

    final now = tz.TZDateTime.now(tz.local);

    if (daily > 0) {
      await _scheduleDailyAt(
        id: _kIdDailyReminder,
        hour: 22,
        minute: 0,
        title: 'Habits due today',
        body: '$daily daily habit${daily == 1 ? '' : 's'} still to complete — only 2 hours left!',
        now: now,
      );
    }

    if (weekly > 0) {
      // Fire at 10pm on the last day of this week.
      final weekEnd = _endOfCurrentWeek(now);
      if (!weekEnd.isBefore(now)) {
        final scheduled = tz.TZDateTime(
            tz.local, weekEnd.year, weekEnd.month, weekEnd.day, 22, 0);
        if (scheduled.isAfter(now)) {
          await _plugin.zonedSchedule(
            _kIdWeeklyReminder,
            'Weekly habits due',
            '$weekly weekly habit${weekly == 1 ? '' : 's'} still to complete this week.',
            scheduled,
            _details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    }

    if (monthly > 0) {
      // Fire at 10pm on the last day of this month.
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      final scheduled = tz.TZDateTime(tz.local, now.year, now.month, lastDay, 22, 0);
      if (scheduled.isAfter(now)) {
        await _plugin.zonedSchedule(
          _kIdMonthlyReminder,
          'Monthly habits due',
          '$monthly monthly habit${monthly == 1 ? '' : 's'} still to complete this month.',
          scheduled,
          _details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }

  static Future<void> _scheduleDailyAt({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required tz.TZDateTime now,
  }) async {
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static DateTime _endOfCurrentWeek(DateTime now) {
    // ISO week: ends Sunday (weekday==7)
    final daysUntilSunday = 7 - now.weekday;
    return now.add(Duration(days: daysUntilSunday));
  }
}
