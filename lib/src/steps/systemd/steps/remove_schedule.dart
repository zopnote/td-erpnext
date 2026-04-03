import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/steps/systemd/systemd.dart';

class RemoveScheduleSettings
    with
        StepWiser<
          Systemd,
          RemoveScheduleSettings,
          SystemdRemoveSchedule
        > {
  @override
  SystemdRemoveSchedule create() => SystemdRemoveSchedule();
}

class SystemdRemoveSchedule extends SystemdStep<RemoveScheduleSettings> {
  @override
  Step configure() {

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
          programs: ["systemctl"],
          onFailure: (context, programs) =>
              context.pop("Systemd is not available."),
        ),
        // Stop and disable timer
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
        // Stop service if running
        Shell(
          program: "systemctl",
          arguments: ["stop", "${step.serviceName}-scheduler.service"],
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
