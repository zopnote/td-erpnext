import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/steps/systemd/systemd.dart';

class SetupScheduleSettings
    with StepWiser<Systemd, SetupScheduleSettings, SetupSchedule> {
  final List<String> arguments;
  final String? executablePath;
  final String? description;
  final Duration interval;
  const SetupScheduleSettings({
    required this.arguments,
    this.executablePath,
    this.description,
    this.interval = const Duration(days: 14),
  });
  @override
  SetupSchedule create() => SetupSchedule();
}

class SetupSchedule extends SystemdStep<SetupScheduleSettings> {
  @override
  Step configure() {
    final String schedule = Systemd.durationToSchedule(wise.interval);
    final String exePath = wise.executablePath ?? Platform.resolvedExecutable;
    final String serviceFilePath =
        '/etc/systemd/system/${step.serviceName}-scheduler.service';
    final String timerFilePath =
        '/etc/systemd/system/${step.serviceName}-scheduler.timer';
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
          arguments: ["stop", "${step.serviceName}-scheduler.timer"],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["disable", "${step.serviceName}-scheduler.timer"],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["stop", "${step.serviceName}-scheduler.service"],
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
            "echo '${step.recurringService(exePath, wise.arguments.join(" "))}' | tee $serviceFilePath > /dev/null",
          ],
          options: options,
        ),
        // Write timer file
        Shell(
          program: "sh",
          arguments: [
            "-c",
            "echo '${step.timerService(schedule)}' | tee $timerFilePath > /dev/null",
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
          arguments: ["enable", "${step.serviceName}-scheduler.timer"],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["start", "${step.serviceName}-scheduler.timer"],
          options: options,
        ),
      ],
    );
  }
}
