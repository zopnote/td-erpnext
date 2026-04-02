import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/systemd/systemd.dart';

extension SystemdScheduleExtension on Systemd {
  /// Removes the systemd scheduler (timer and service) with the given [serviceName].
  Step removeSchedule() {
    final String serviceFilePath =
        '/etc/systemd/system/$serviceName-scheduler.service';
    final String timerFilePath =
        '/etc/systemd/system/$serviceName-scheduler.timer';
    final ProcessInterfaceOptions options = const ProcessInterfaceOptions(
      runAsAdministrator: true,
    );

    return Chain(
      steps: [
        Check(
          programs: ["systemctl"],
          onFailure: (context, programs) =>
              context.pop("Systemd is not available."),
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

  /// Updates the duration of an existing scheduler timer.
  ///
  /// This will update the `.timer` file and reload systemd to apply the changes.
  Step updateSchedule({required Duration interval}) {
    final String schedule = Systemd.durationToSchedule(interval);
    final String timerFilePath =
        '/etc/systemd/system/$serviceName-scheduler.timer';
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
            "echo '${timerService(schedule)}' | tee $timerFilePath > /dev/null",
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

  /// Checks if a recurring (timer) service with the given [serviceName] is installed.
  ///
  /// Returns `true` if the `.timer` file exists in `/etc/systemd/system/`.
  bool hasSchedule() {
    return File(
      '/etc/systemd/system/$serviceName-scheduler.timer',
    ).existsSync();
  }

  /// Sets up a systemd service and a timer to run this program at a recurring interval.
  ///
  /// * Creates a `.service` file (the "task") that tells the system to run
  ///   the program with a specific argument as the root user.
  /// * Creates a `.timer` file (the "schedule") based on the [interval].
  /// * `Persistent=true` ensures that if the computer was off during the
  ///   scheduled time, the task will run immediately after the next boot.
  /// * The task is of type `oneshot`, meaning it's expected to run, finish,
  ///   and then stop until the next time the timer triggers it.
  Step setupSchedule({
    required final List<String> arguments,
    final String? executablePath,
    final String? description,
    final Duration interval = const Duration(days: 14),
  }) {
    final String schedule = Systemd.durationToSchedule(interval);
    final String exePath = executablePath ?? Platform.resolvedExecutable;
    final String serviceFilePath =
        '/etc/systemd/system/$serviceName-scheduler.service';
    final String timerFilePath =
        '/etc/systemd/system/$serviceName-scheduler.timer';
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
            "echo '${recurringService(exePath, arguments.join(" "))}' | tee $serviceFilePath > /dev/null",
          ],
          options: options,
        ),
        // Write timer file
        Shell(
          program: "sh",
          arguments: [
            "-c",
            "echo '${timerService(schedule)}' | tee $timerFilePath > /dev/null",
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
}
