import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/systemd/systemd.dart';

extension SystemdAutostartExtension on Systemd {
  /// Sets up a systemd service that starts automatically when the system boots.
  ///
  /// * Creates a `.service` file that defines a background task.
  /// * `Type=simple` means the service starts immediately and stays running.
  /// * `WantedBy=multi-user.target` tells Linux to start this service as soon
  ///   as the system is ready for regular use (the "multi-user" state).
  /// * `Restart=on-failure` ensures that if the program crashes, systemd will
  ///   automatically try to start it again, providing better reliability.
  Step setupAutostart({
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
            "echo '${bootService(exePath, arguments.join(", "))}' | tee $serviceFilePath > /dev/null",
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
  bool hasAutostart() {
    return File('/etc/systemd/system/$serviceName.service').existsSync();
  }

  /// Removes the systemd boot service with the given [serviceName].
  Step removeAutostart() {
    final String serviceFilePath = '/etc/systemd/system/$serviceName.service';
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
