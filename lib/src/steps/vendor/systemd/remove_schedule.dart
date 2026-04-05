import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/steps/vendor/systemd.dart';

class RemoveSchedule extends SystemdStep {
  /// Removes the systemd scheduler (timer and service) with the given [serviceName].
  const RemoveSchedule();
  @override
  Step run(ProcessInterfaceOptions options) {
    final String serviceFilePath =
        '/etc/systemd/system/$serviceName-scheduler.service';
    final String timerFilePath =
        '/etc/systemd/system/$serviceName-scheduler.timer';

    return Chain(
      steps: [
        Check(
          programs: ["systemctl"],
          onFailure: (programs) => throw Exception("Systemd is not available."),
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
}
