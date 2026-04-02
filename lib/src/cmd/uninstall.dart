import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/uninstall.dart';

final NatrixCommand uninstallCommand = NatrixCommand(
  id: "uninstall",
  description: "Removes the installation securely.",
  flags: [
    NatrixBoolFlag(id: "hard", tooltip: "Deletes all backups.", value: false),
  ],
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    await runWorkflow(
      Uninstall(
        appDirectoryPath: settingsAtProgramStart.appDirectoryPath,
        backupsDirectoryPath: settingsAtProgramStart.backupDestinationPath,
        removeBackups: options.getFlag("hard").value,
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
