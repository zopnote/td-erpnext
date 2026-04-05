import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/steps/vendor/systemd.dart';

class SetupSchedule extends SystemdStep {
  final List<String> args;
  final String? executablePath;
  final String? description;
  final Duration interval;
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
  const SetupSchedule({
    required this.args,
    this.executablePath,
    this.description,
    this.interval = const Duration(days: 14),
  });

  @override
  Step run(ProcessInterfaceOptions options) {
    final String schedule = durationToSchedule(interval);
    final String exePath = executablePath ?? Platform.resolvedExecutable;
    final String serviceFilePath =
        '/etc/systemd/system/$serviceName-scheduler.service';
    final String timerFilePath =
        '/etc/systemd/system/$serviceName-scheduler.timer';

    return Chain(
      steps: [
        Check(
          programs: ["systemctl", "systemd"],
          onFailure: (programs) => throw Exception(
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
            "echo '${recurringService(exePath, args.join(" "))}' | tee $serviceFilePath > /dev/null",
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
