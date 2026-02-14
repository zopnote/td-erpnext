import 'dart:io';
import 'package:stepflow/io.dart';
import 'package:stepflow/core.dart';

String _recurringService(
  String executablePath,
  String argument,
  String serviceName,
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

String _timerService(String serviceName, String schedule) =>
    """
[Unit]
Description=Timer for $serviceName

[Timer]
OnCalendar=$schedule
Persistent=true

[Install]
WantedBy=timers.target
""";

String _bootService(String exePath, String argument, String serviceName) =>
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

String _durationToSchedule(Duration d) {
  if (d.inDays == 14 && d.inHours % 24 == 0 && d.inMinutes % 60 == 0) return 'fortnightly';
  if (d.inDays == 7 && d.inHours % 24 == 0 && d.inMinutes % 60 == 0) return 'weekly';
  if (d.inDays == 1 && d.inHours % 24 == 0 && d.inMinutes % 60 == 0) return 'daily';
  if (d.inDays == 0 && d.inHours == 1 && d.inMinutes % 60 == 0) return 'hourly';
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

Duration _scheduleToDuration(String schedule) {
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
        final hours = int.tryParse(hoursPart.split(':').first.split('/').last);
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
    return Duration(days: days, hours: hours, minutes: minutes, seconds: seconds);
  }

  return const Duration(days: 14); // Default
}

/// This class provides methods to set up systemd services on Linux.
///
/// systemd is a system and service manager for Linux. It uses "unit files"
/// to define how services should be started and managed.
///
/// There are two main components used here:
/// 1. **Services (.service)**: These define the actual command to run.
/// 2. **Timers (.timer)**: These act like alarm clocks that tell systemd
///    when to trigger a specific service.
class Systemd {
  const Systemd._internal();
  /// Sets up a systemd service and a timer to run this program at a recurring interval.
  ///
  /// * Creates a `.service` file (the "task") that tells the system to run
  ///   the program with a specific argument as the root user.
  /// * Creates a `.timer` file (the "schedule") based on the [interval].
  /// * `Persistent=true` ensures that if the computer was off during the
  ///   scheduled time, the task will run immediately after the next boot.
  /// * The task is of type `oneshot`, meaning it's expected to run, finish,
  ///   and then stop until the next time the timer triggers it.
  static Step setupScheduler({
    required final String serviceName,
    required final List<String> arguments,
    final String? executablePath,
    final String? description,
    final Duration interval = const Duration(days: 14),
  }) {
    final String schedule = _durationToSchedule(interval);
    final String exePath = executablePath ?? Platform.resolvedExecutable;
    final String serviceFilePath = '/etc/systemd/system/$serviceName-scheduler.service';
    final String timerFilePath = '/etc/systemd/system/$serviceName-scheduler.timer';
    final ProcessInterfaceOptions options = const ProcessInterfaceOptions(
      runAsAdministrator: true,
    );

    return Chain(
      steps: [
        Check(
          programs: ["systemctl", "systemd"],
          onFailure: (context, programs) => context.pop(
            "Systemd is not available. Missing programs: ${programs.join(", ")}",
          ),
        ),
        // Clean up existing installation if present
        Shell(
          program: "systemctl",
          arguments: ["stop", "$serviceName-scheduler.timer"],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["disable", "$serviceName-scheduler.timer"],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["stop", "$serviceName-scheduler.service"],
          options: options,
        ),
        Shell(
          program: "rm",
          arguments: ["-f", serviceFilePath, timerFilePath],
          options: options,
        ),
        // Write service file
        Shell(
          program: "sh",
          arguments: [
            "-c",
            "echo '${_recurringService(exePath, arguments.join(" "), serviceName)}' | tee $serviceFilePath > /dev/null",
          ],
          options: options,
        ),
        // Write timer file
        Shell(
          program: "sh",
          arguments: [
            "-c",
            "echo '${_timerService(serviceName, schedule)}' | tee $timerFilePath > /dev/null",
          ],
          options: options,
        ),
        // Reload systemd and enable/start timer
        Shell(
          program: "systemctl",
          arguments: ["daemon-reload"],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["enable", "$serviceName-scheduler.timer"],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["start", "$serviceName-scheduler.timer"],
          options: options,
        ),
      ],
    );
  }

  /// Sets up a systemd service that starts automatically when the system boots.
  ///
  /// * Creates a `.service` file that defines a background task.
  /// * `Type=simple` means the service starts immediately and stays running.
  /// * `WantedBy=multi-user.target` tells Linux to start this service as soon
  ///   as the system is ready for regular use (the "multi-user" state).
  /// * `Restart=on-failure` ensures that if the program crashes, systemd will
  ///   automatically try to start it again, providing better reliability.
  static Step setupBoot({
    required final String serviceName,
    required final List<String> arguments,
    final String? executablePath,
    final String? description,
  }) {
    final String exePath = executablePath ?? Platform.resolvedExecutable;
    final String serviceFilePath = '/etc/systemd/system/$serviceName.service';
    final ProcessInterfaceOptions options = const ProcessInterfaceOptions(
      runAsAdministrator: true,
    );
    return Chain(
      steps: [
        Check(
          programs: ["systemctl", "systemd"],
          onFailure: (context, programs) => context.pop(
            "Systemd is not available. Missing programs: ${programs.join(", ")}",
          ),
        ),
        // Clean up existing installation if present
        Shell(
          program: "systemctl",
          arguments: ["stop", serviceName],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["disable", serviceName],
          options: options,
        ),
        Shell(
          program: "rm",
          arguments: ["-f", serviceFilePath],
          options: options,
        ),
        // Write service file
        Shell(
          program: "sh",
          arguments: [
            "-c",
            "echo '${_bootService(exePath, arguments.join(", "), serviceName)}' | tee $serviceFilePath > /dev/null",
          ],
          options: options,
        ),
        // Reload systemd and enable/start service
        Shell(
          program: "systemctl",
          arguments: ["daemon-reload"],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["enable", serviceName],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["start", serviceName],
          options: options,
        ),
      ],
    );
  }

  /// Checks if a boot service with the given [serviceName] is installed.
  ///
  /// Returns `true` if the `.service` file exists in `/etc/systemd/system/`.
  static bool isBootInstalled(String serviceName) {
    return File('/etc/systemd/system/$serviceName.service').existsSync();
  }

  /// Checks if a recurring (timer) service with the given [serviceName] is installed.
  ///
  /// Returns `true` if the `.timer` file exists in `/etc/systemd/system/`.
  static bool isSchedulerInstalled(String serviceName) {
    return File('/etc/systemd/system/$serviceName-scheduler.timer').existsSync();
  }

  /// Updates the duration of an existing scheduler timer.
  ///
  /// This will update the `.timer` file and reload systemd to apply the changes.
  static Step updateSchedulerDuration({
    required String serviceName,
    required Duration interval,
  }) {
    final String schedule = _durationToSchedule(interval);
    final String timerFilePath = '/etc/systemd/system/$serviceName-scheduler.timer';
    final ProcessInterfaceOptions options = const ProcessInterfaceOptions(
      runAsAdministrator: true,
    );

    return Chain(
      steps: [
        Check(
          programs: ["systemctl", "systemd"],
          onFailure: (context, programs) => context.pop(
            "Systemd is not available. Missing programs: ${programs.join(", ")}",
          ),
        ),
        // Overwrite the timer file completely with the new schedule
        Shell(
          program: "sh",
          arguments: [
            "-c",
            "echo '${_timerService(serviceName, schedule)}' | tee $timerFilePath > /dev/null",
          ],
          options: options,
        ),
        // Reload systemd and restart timer
        Shell(
          program: "systemctl",
          arguments: ["daemon-reload"],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["restart", "$serviceName-scheduler.timer"],
          options: options,
        ),
      ],
    );
  }

  /// Returns the current duration of the scheduler timer for the given [serviceName].
  ///
  /// If the timer is not installed or cannot be read, it returns a default of 14 days.
  static Duration getSchedulerDuration(String serviceName) {
    final File timerFile = File('/etc/systemd/system/$serviceName-scheduler.timer');
    if (!timerFile.existsSync()) {
      return const Duration(days: 14);
    }

    try {
      final lines = timerFile.readAsLinesSync();
      for (var line in lines) {
        if (line.trim().startsWith('OnCalendar=')) {
          final schedule = line.split('=').last.trim();
          return _scheduleToDuration(schedule);
        }
      }
    } catch (_) {
      // Return default if error reading file
    }

    return const Duration(days: 14);
  }

  /// Removes the systemd scheduler (timer and service) with the given [serviceName].
  static Step removeScheduler(String serviceName) {
    final String serviceFilePath = '/etc/systemd/system/$serviceName-scheduler.service';
    final String timerFilePath = '/etc/systemd/system/$serviceName-scheduler.timer';
    final ProcessInterfaceOptions options = const ProcessInterfaceOptions(
      runAsAdministrator: true,
    );

    return Chain(
      steps: [
        Check(
          programs: ["systemctl"],
          onFailure: (context, programs) => context.pop(
            "Systemd is not available.",
          ),
        ),
        // Stop and disable timer
        Shell(
          program: "systemctl",
          arguments: ["stop", "$serviceName-scheduler.timer"],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["disable", "$serviceName-scheduler.timer"],
          options: options,
        ),
        // Stop service if running
        Shell(
          program: "systemctl",
          arguments: ["stop", "$serviceName-scheduler.service"],
          options: options,
        ),
        // Remove files
        Shell(
          program: "rm",
          arguments: ["-f", serviceFilePath, timerFilePath],
          options: options,
        ),
        // Reload systemd
        Shell(
          program: "systemctl",
          arguments: ["daemon-reload"],
          options: options,
        ),
      ],
    );
  }

  /// Removes the systemd boot service with the given [serviceName].
  static Step removeBoot(String serviceName) {
    final String serviceFilePath = '/etc/systemd/system/$serviceName.service';
    final ProcessInterfaceOptions options = const ProcessInterfaceOptions(
      runAsAdministrator: true,
    );

    return Chain(
      steps: [
        Check(
          programs: ["systemctl"],
          onFailure: (context, programs) => context.pop(
            "Systemd is not available.",
          ),
        ),
        // Stop and disable service
        Shell(
          program: "systemctl",
          arguments: ["stop", serviceName],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["disable", serviceName],
          options: options,
        ),
        // Remove file
        Shell(
          program: "rm",
          arguments: ["-f", serviceFilePath],
          options: options,
        ),
        // Reload systemd
        Shell(
          program: "systemctl",
          arguments: ["daemon-reload"],
          options: options,
        ),
      ],
    );
  }
}
