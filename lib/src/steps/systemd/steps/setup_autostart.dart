import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

import '../systemd.dart';

class SetupAutostartSettings
    with
        StepWiser<
          Systemd,
          SetupAutostartSettings,
          SetupAutostart
        > {
  final List<String> arguments;
  final String? executablePath;
  final String? description;
  const SetupAutostartSettings({
    required this.arguments,
    this.executablePath,
    this.description,
  });
  @override
  SetupAutostart create() => SetupAutostart();
}

class SetupAutostart extends SystemdStep<SetupAutostartSettings> {
  @override
  Step configure() {
    final String exePath = wise.executablePath ?? Platform.resolvedExecutable;
    final String serviceFilePath =
        '/etc/systemd/system/${step.serviceName}.service';
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
          arguments: ["stop", step.serviceName],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["disable", step.serviceName],
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
            "echo '${step.bootService(exePath, wise.arguments.join(", "))}' | tee $serviceFilePath > /dev/null",
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
          arguments: ["enable", step.serviceName],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["start", step.serviceName],
          options: options,
        ),
      ],
    );
  }
}
