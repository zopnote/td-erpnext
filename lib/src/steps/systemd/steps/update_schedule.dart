import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/steps/systemd/systemd.dart';

class UpdateScheduleSettings
    with StepWiser<Systemd, UpdateScheduleSettings, UpdateSchedule> {
  final Duration interval;
  const UpdateScheduleSettings({required this.interval});
  @override
  UpdateSchedule create() => UpdateSchedule();
}

class UpdateSchedule extends SystemdStep<UpdateScheduleSettings> {
  @override
  Step configure() {
    final String schedule = Systemd.durationToSchedule(wise.interval);
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
        // Overwrite the timer file completely with the new schedule
        Shell(
          program: "sh",
          arguments: [
            "-c",
            "echo '${step.timerService(schedule)}' | tee $timerFilePath > /dev/null",
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
          arguments: ["restart", "${step.serviceName}-scheduler.timer"],
          options: options,
        ),
      ],
    );
  }
}
