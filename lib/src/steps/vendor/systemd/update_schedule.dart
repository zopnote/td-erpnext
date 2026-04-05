import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

import 'package:td_erpnext/src/steps/vendor/systemd.dart';

class UpdateSchedule extends SystemdStep {
  final Duration interval;

  /**
      Updates the duration of an existing scheduler timer.

      This will update the `.timer` file and reload systemd to apply the changes.
   */
  const UpdateSchedule({required this.interval});

  @override
  Step run(ProcessInterfaceOptions options) {
    final String schedule = durationToSchedule(interval);
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
        // Overwrite the timer file completely with the new schedule
        Shell(
          program: "sh",
          arguments: [
            "-c",
            "echo '${timerService(schedule)}' | tee $timerFilePath > /dev/null",
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
          arguments: ["restart", "$serviceName-scheduler.timer"],
          options: options,
        ),
      ],
    );
  }
}
