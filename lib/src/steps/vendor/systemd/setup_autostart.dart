import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

import '../systemd.dart';

class SetupAutostart extends SystemdStep {
  final List<String> args;
  final String? executablePath;
  final String? description;
  /**
      Sets up a systemd service that starts automatically when the system boots.

   * Creates a `.service` file that defines a background task.
   * `Type=simple` means the service starts immediately and stays running.
   * `WantedBy=multi-user.target` tells Linux to start this service as soon
      as the system is ready for regular use (the "multi-user" state).
   * `Restart=on-failure` ensures that if the program crashes, systemd will
      automatically try to start it again, providing better reliability.
   */
  const SetupAutostart({
    required this.args,
    this.executablePath,
    this.description,
  });

  @override
  Step run(ProcessInterfaceOptions options) {
    final String exePath = executablePath ?? Platform.resolvedExecutable;
    final String serviceFilePath = '/etc/systemd/system/$serviceName.service';

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
            "echo '${bootService(exePath, args.join(", "))}' | tee $serviceFilePath > /dev/null",
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
}
