import 'dart:io';

import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/settings.dart';

import 'steps/remove_autostart.dart';
import 'steps/remove_schedule.dart';
import 'steps/setup_autostart.dart';
import 'steps/setup_schedule.dart';
import 'steps/update_schedule.dart';

abstract class SystemdStep<
  C extends StepWiser<Systemd, C, SingleStep<Systemd, C>>
>
    extends SingleStep<Systemd, C> {}

/**
  This class provides methods to set up systemd services on Linux.

   systemd is a system and service manager for Linux. It uses "unit files"
   to define how services should be started and managed.

   There are two main components used here:
   1. **Services (.service)**: These define the actual command to run.
   2. **Timers (.timer)**: These act like alarm clocks that tell systemd
      when to trigger a specific service.
 */
final class Systemd extends CollectionStep<Systemd> {
  final String serviceName;
  static late final Systemd _instance;
  static bool initialized = false;
  Systemd._internal(this.serviceName) {
    _instance = this;
    initialized = true;
  }
  factory Systemd.get() =>
      initialized ? _instance : Systemd._internal(Settings.serviceName);

  /**
    Sets up a systemd service and a timer to run this program at a recurring interval.

     * Creates a `.service` file (the "task") that tells the system to run
       the program with a specific argument as the root user.
     * Creates a `.timer` file (the "schedule") based on the [interval].
     * `Persistent=true` ensures that if the computer was off during the
       scheduled time, the task will run immediately after the next boot.
     * The task is of type `oneshot`, meaning it's expected to run, finish,
       and then stop until the next time the timer triggers it.
   */
  Step setupSchedule(final SetupScheduleSettings settings) =>
      stepwise<SetupSchedule, SetupScheduleSettings>(settings);

  /// Removes the systemd scheduler (timer and service) with the given [serviceName].
  Step removeSchedule(final RemoveScheduleSettings settings) =>
      stepwise<SystemdRemoveSchedule, RemoveScheduleSettings>(settings);

  /**
    Updates the duration of an existing scheduler timer.

    This will update the `.timer` file and reload systemd to apply the changes.
   */
  Step updateSchedule(final UpdateScheduleSettings settings) =>
      stepwise<UpdateSchedule, UpdateScheduleSettings>(settings);

  /**
    Sets up a systemd service that starts automatically when the system boots.

     * Creates a `.service` file that defines a background task.
     * `Type=simple` means the service starts immediately and stays running.
     * `WantedBy=multi-user.target` tells Linux to start this service as soon
       as the system is ready for regular use (the "multi-user" state).
     * `Restart=on-failure` ensures that if the program crashes, systemd will
       automatically try to start it again, providing better reliability.
   */
  Step setupAutostart(final SetupAutostartSettings settings) =>
      stepwise<SetupAutostart, SetupAutostartSettings>(settings);

  /// Removes the systemd boot service with the given [serviceName].
  Step removeAutostart(final RemoveAutostartSettings settings) =>
      stepwise<RemoveAutostart, RemoveAutostartSettings>(settings);

  /// Checks if a recurring (timer) service with the given [serviceName] is installed.
  ///
  /// Returns `true` if the `.timer` file exists in `/etc/systemd/system/`.
  bool hasSchedule() {
    return File(
      '/etc/systemd/system/$serviceName-scheduler.timer',
    ).existsSync();
  }

  /// Checks if a boot service with the given [serviceName] is installed.
  ///
  /// Returns `true` if the `.service` file exists in `/etc/systemd/system/`.
  bool hasAutostart() {
    return File('/etc/systemd/system/$serviceName.service').existsSync();
  }

  String recurringService(String executablePath, String argument) =>
      """
[Unit]
Description=Recurring service for $serviceName
After=network.target

[Service]
Type=oneshot
User=root
Group=root
ExecStart=$executablePath $argument
""";

  String timerService(String schedule) =>
      """
[Unit]
Description=Timer for $serviceName

[Timer]
OnCalendar=$schedule
Persistent=true

[Install]
WantedBy=timers.target
""";

  String bootService(String exePath, String argument) =>
      """
[Unit]
Description=Boot service for $serviceName
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=$exePath $argument
Restart=on-failure

[Install]
WantedBy=multi-user.target
""";

  static String durationToSchedule(Duration d) {
    if (d.inDays == 14 && d.inHours % 24 == 0 && d.inMinutes % 60 == 0)
      return 'fortnightly';
    if (d.inDays == 7 && d.inHours % 24 == 0 && d.inMinutes % 60 == 0)
      return 'weekly';
    if (d.inDays == 1 && d.inHours % 24 == 0 && d.inMinutes % 60 == 0)
      return 'daily';
    if (d.inDays == 0 && d.inHours == 1 && d.inMinutes % 60 == 0)
      return 'hourly';
    if (d.inDays == 0 && d.inHours == 0 && d.inMinutes == 1) return 'minutely';

    final List<String> parts = [];
    if (d.inDays > 0) parts.add('${d.inDays}d');
    final int hours = d.inHours % 24;
    if (hours > 0) parts.add('${hours}h');
    final int minutes = d.inMinutes % 60;
    if (minutes > 0) parts.add('${minutes}m');
    final int seconds = d.inSeconds % 60;
    if (seconds > 0) parts.add('${seconds}s');

    if (parts.isEmpty) return 'minutely';
    return parts.join(' ');
  }

  static Duration scheduleToDuration(String schedule) {
    switch (schedule) {
      case 'fortnightly':
        return const Duration(days: 14);
      case 'weekly':
        return const Duration(days: 7);
      case 'daily':
        return const Duration(days: 1);
      case 'hourly':
        return const Duration(hours: 1);
      case 'minutely':
        return const Duration(minutes: 1);
    }

    // Handle custom formats like '*-*-01/14 00:00:00' (legacy) or '1d 12h'
    if (schedule.contains('/') || schedule.contains(':')) {
      final parts = schedule.split(' ');

      if (schedule.startsWith('*-*-01/')) {
        final days = int.tryParse(parts[0].split('/').last);
        if (days != null) return Duration(days: days);
      } else if (schedule.startsWith('*-*-* ')) {
        final hoursPart = parts[1];
        if (hoursPart.contains('/')) {
          final hours = int.tryParse(
            hoursPart.split(':').first.split('/').last,
          );
          if (hours != null) return Duration(hours: hours);
        }
      } else if (schedule.startsWith('*:0/')) {
        final minutes = int.tryParse(schedule.split('/').last);
        if (minutes != null) return Duration(minutes: minutes);
      }
    }

    // Handle composite duration strings like "1d 12h 30m"
    final regex = RegExp(r'(\d+)([dhms])');
    final matches = regex.allMatches(schedule);

    if (matches.isNotEmpty) {
      int days = 0;
      int hours = 0;
      int minutes = 0;
      int seconds = 0;

      for (final match in matches) {
        final value = int.parse(match.group(1)!);
        final unit = match.group(2);
        switch (unit) {
          case 'd':
            days = value;
            break;
          case 'h':
            hours = value;
            break;
          case 'm':
            minutes = value;
            break;
          case 's':
            seconds = value;
            break;
        }
      }
      return Duration(
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      );
    }

    return const Duration(days: 14); // Default
  }
}
