import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/restore.dart';
import 'package:td_erpnext/src/steps/docker.dart';
import 'package:td_erpnext/src/settings.dart';

final NatrixCommand backupsRestoreLastCommand = NatrixCommand(
  id: "last",
  description: "Restores the last backup.",
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    final Settings settings = Settings.load();

    await runWorkflow(
      ERPNextRestore(
        container: DockerContainer(settings.dockerContainerName.value),
        restoreLast: true,
        appDirectoryPath: settings.appDirectoryPath,
        currentSiteName: settings.currentSite.value,
        backupsDirectoryPath: settings.backupDestinationPath.value,
        workingDirectory: settings.appDirectoryPath,
        onCallback: (context, chars, error) => context.send(
          Response(
            String.fromCharCodes(chars),
            error ? Level.error : Level.normal,
          ),
        ),
      ),
      (response) => io.newLine(
        text: NatrixText(response.message),
        output: response.isError ? .stderr : .stdout,
      ),
    );
  },
);
