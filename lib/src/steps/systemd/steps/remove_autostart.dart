import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/steps/systemd/systemd.dart';

class RemoveAutostartSettings
    with
        StepWiser<
          Systemd,
          RemoveAutostartSettings,
          RemoveAutostart
        > {
  const RemoveAutostartSettings();
  @override
  RemoveAutostart create() => RemoveAutostart();
}

class RemoveAutostart
    extends SystemdStep<RemoveAutostartSettings> {
  @override
  Step configure() {
    final String serviceFilePath =
        '/etc/systemd/system/${step.serviceName}.service';
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
          arguments: ["stop", step.serviceName],
          options: options,
        ),
        Shell(
          program: "systemctl",
          arguments: ["disable", step.serviceName],
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
