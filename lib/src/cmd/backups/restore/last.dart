import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/steps/backup_restore.dart';

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
    await runWorkflow(const RestoreBackup(restoreLast: true));
  },
);
