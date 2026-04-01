export 'autostart.dart';
export 'schedule.dart';

/// This class provides methods to set up systemd services on Linux.
///
/// systemd is a system and service manager for Linux. It uses "unit files"
/// to define how services should be started and managed.
///
/// There are two main components used here:
/// 1. **Services (.service)**: These define the actual command to run.
/// 2. **Timers (.timer)**: These act like alarm clocks that tell systemd
///    when to trigger a specific service.
final class Systemd {
  final String serviceName;
  const Systemd(this.serviceName);

  String recurringService(
    String executablePath,
    String argument
  ) =>
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

  String bootService(
    String exePath,
    String argument,
  ) =>
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
