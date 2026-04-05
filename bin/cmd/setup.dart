import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/setup.dart';
import 'package:td_erpnext/src/steps/vendor/docker.dart' as docker;
import 'package:td_erpnext/src/steps/vendor/systemd.dart' as systemd;
import 'package:td_erpnext/src/utils.dart';

final NatrixCommand setupCommand = NatrixCommand(
  id: "setup",
  description: "Installs and starts frappe erpnext.",
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    final Settings settings = Settings.fromDisk();

    await runWorkflow(
      Chain(
        steps: [
          const PrintNatrixLine(text: NatrixText("Setup docker container...")),
          const Setup(),
          const PrintNatrixLine(
            text: NatrixText("Set restart policy of container..."),
          ),
          docker.Update(
            containers: [docker.Container(settings.frontendContainer.value)],
            restart: docker.RestartPolicy.no,
          ),
          const PrintNatrixLine(
            text: NatrixText("Add systemd boot service..."),
          ),
          systemd.SetupAutostart(args: ["start"]),
        ],
      ),
      (e) => io.newLine(
        text: NatrixText(e.exception.toString(), foreground: .red),
        output: .stderr,
      ),
    );
  },
);
