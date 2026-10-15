import 'dart:io';

import 'package:natrix/io.dart';
import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:stepflow_docker/docker.dart' as docker;

import '../exception.dart';
import 'recreate_directory.dart';
import 'natrix.dart';

final class CreateBackup extends ConfigureStep {
  final NatrixStdoutSink? output;
  const CreateBackup({this.output});

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
    final Settings settings = Settings.fromDisk();
    final docker.OutputCallback callback = (chars) {
      NatrixStdio().pipe(
        text: NatrixText(String.fromCharCodes(chars), foreground: .grayAccent),
        output: output ?? .stdout,
      );
    };
    final String backupPath = path.join(
      settings.backupStoragePath.value,
      DateTime.now()
          .toLocal()
          .toIso8601String()
          .substring(0, 18)
          .replaceAll(":", "_"),
    );
    final docker.Container backend = docker.Container(
      settings.backendContainer.value,
    );
    return Chain(
      steps: [
        Conditional(
          condition: !Directory(backupPath).existsSync(),
          child: RecreateDirectory(backupPath, recursive: true),
        ),
        docker.Execute(
          container: backend,
          program: "bench",
          args: ["--site", Settings.siteName, "backup", "--with-files"],
          callback: callback,
        ),
        docker.Copy(
          source: docker.Location.container(
            backend,
            "/home/frappe/frappe-bench/sites/${Settings.siteName}/private/backups/",
          ),
          destination: docker.Location.host(backupPath),
          callback: callback,
        ),
        docker.Copy(
          source: docker.Location.container(
            backend,
            "/home/frappe/frappe-bench/sites/${Settings.siteName}/site_config.json",
          ),
          destination: docker.Location.host(backupPath),
          callback: callback,
        ),
        PrintNatrixLine(
          text:
              NatrixText("Backup ") +
              NatrixText(
                path.basename(backupPath),
                foreground: NatrixColor.cyanAccent,
              ) +
              NatrixText(" stored under ${path.dirname(backupPath)}."),
        ),
      ],
    );
  }
}
