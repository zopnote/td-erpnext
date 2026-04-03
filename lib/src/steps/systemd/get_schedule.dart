import 'dart:io';

import 'systemd.dart';

extension SystemdScheduleExtension on Systemd {
  /// Returns the current duration of the scheduler timer for the given [serviceName].
  ///
  /// If the timer is not installed or cannot be read, it returns a default of 14 days.
  Duration getSchedule() {
    final File timerFile = File(
      '/etc/systemd/system/$serviceName-scheduler.timer',
    );
    if (!timerFile.existsSync()) {
      return const Duration(days: 14);
    }

    try {
      final lines = timerFile.readAsLinesSync();
      for (var line in lines) {
        if (line.trim().startsWith('OnCalendar=')) {
          final schedule = line.split('=').last.trim();
          return Systemd.scheduleToDuration(schedule);
        }
      }
    } catch (_) {
      // Return default if error reading file
    }

    return const Duration(days: 14);
  }
}
