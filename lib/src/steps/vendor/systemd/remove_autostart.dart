import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/steps/vendor/systemd.dart';

class RemoveAutostart extends SystemdStep {
  /// Removes the systemd boot service with the given [serviceName].
  const RemoveAutostart();

  @override
  Step run(ProcessInterfaceOptions options) {
    final String serviceFilePath = '/etc/systemd/system/$serviceName.service';
    return Chain(
      steps: [
        Check(
          programs: ["systemctl"],
          onFailure: (programs) => throw Exception("Systemd is not available."),
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
