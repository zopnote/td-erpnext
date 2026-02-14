import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/setup.dart';
import 'package:td_erpnext/src/docker.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/log_color.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/systemd.dart';

Future<Response> backupsCommand(CommandInformation info) async {
  final bP = info.getFlag("interval") as DurationFlag;
  bool changedSchedulerDuration =
      Systemd.isSchedulerInstalled(Settings.serviceName) &&
      Systemd.getSchedulerDuration(Settings.serviceName) != bP.value;
  if (changedSchedulerDuration) {
    final Response lastResponse = await runWorkflow(
      Systemd.updateSchedulerDuration(
        serviceName: Settings.serviceName,
        interval: bP.value,
      ),
      (response) {
        if (response.isError) {
          stderr.writeln(response.message);
          return;
        }
        stdout.writeln(response.message);
      },
    );
    stdout.writeln("Updated backup schedule to ${bP.getFormatted()}.");

    if (lastResponse.isError) {
      return Response("An error occurred.", Level.critical);
    }
  }

  /**
   * Note that the Flags default values are the current settings, loaded from disk,
   * before initializing the programs command line interface.
   *
   * So, when we dump, and no actual changes to the settings were made, we just dump
   * what we loaded before.
   */
  final bSP = info.getFlag(Settings.json(#backupSourcePath)) as TextFlag;
  final bDP = info.getFlag(Settings.json(#backupDestinationPath)) as TextFlag;

  if (bSP.value != settingsAtProgramStart.backupSourcePath ||
      bDP.value != settingsAtProgramStart.backupDestinationPath) {
    final Settings settings = Settings(
      connectionPort: settingsAtProgramStart.connectionPort,
      currentSite: settingsAtProgramStart.currentSite,
      dockerContainerName: settingsAtProgramStart.dockerContainerName,
      appDirectoryName: settingsAtProgramStart.appDirectoryName,
      logDirectoryName: settingsAtProgramStart.logDirectoryName,
      backupSourcePath: bSP.value,
      backupDestinationPath: bDP.value,
    );

    settings.dump();
    return Response(
      "Adjusted the settings to the following: "
      "\n${JsonEncoder.withIndent('  ').convert(settings.document).replaceAll("{", "").replaceAll("}", "").replaceAll("\"", "").replaceAll(",", "")}",
    );
  }

  if (!Systemd.isSchedulerInstalled(Settings.serviceName)) {
    stdout.writeln(LogColor.yellow("Backups are currently disabled."));
  }
  if (changedSchedulerDuration) {
    return Response();
  }
  return Response(info.command.formatSyntax(spacer: 15), Level.normal);
}

Future<Response> backupsEnableCommand(CommandInformation info) async {
  final bP = info.getFlag("interval") as DurationFlag;

  final Response lastResponse = await runWorkflow(
    Chain(
      steps: [
        Systemd.setupScheduler(
          serviceName: Settings.serviceName,
          arguments: ["backups", "create"],
          interval: bP.value,
        ),
      ],
    ),
    (response) {
      if (response.isError) {
        stderr.writeln(response.message);
        return;
      }
      stdout.writeln(response.message);
    },
  );
  if (lastResponse.isError) {
    return Response("An error occurred.", Level.critical);
  }
  return Response(
    "Installed schedule service with a interval of ${bP.getFormatted()}.",
  );
}

Future<Response> backupsDisableCommand(CommandInformation info) async {
  final Response lastResponse = await runWorkflow(
    Chain(steps: [Systemd.removeScheduler(Settings.serviceName)]),
    (response) {
      if (response.isError) {
        stderr.writeln(response.message);
        return;
      }
      stdout.writeln(response.message);
    },
  );
  if (lastResponse.isError) {
    return Response("An error occurred.", Level.critical);
  }
  return Response("Removed the scheduler service.");
}

Future<Response> backupsCreateCommand(CommandInformation info) async {
  final Response lastResponse = await runWorkflow(
    Chain(
      steps: [
        ERPNextBackup(
          container: DockerContainer(
            settingsAtProgramStart.dockerContainerName,
          ),
          currentSiteName: settingsAtProgramStart.currentSite,
          onCallback: (context, chars, error) => context.send(
            Response(
              String.fromCharCodes(chars),
              error ? Level.error : Level.normal,
            ),
          ),
          backupSourcePath: settingsAtProgramStart.backupSourcePath,
          backupDestinationPath: settingsAtProgramStart.backupDestinationPath,
        ),
      ],
    ),
    (response) {
      if (response.isError) {
        stderr.writeln(response.message);
        return;
      }
      stdout.writeln(response.message);
    },
  );
  if (lastResponse.isError) {
    return Response("An error occurred.", Level.critical);
  }
  return Response();
}

Future<Response> backupsRestoreCommand(CommandInformation info) async {
  final Response lastResponse = await runWorkflow(
    Chain(
      steps: [
        ERPNextRestore(
          container: DockerContainer(
            settingsAtProgramStart.dockerContainerName,
          ),
          backupSourcePath: settingsAtProgramStart.backupSourcePath,
          currentSiteName: settingsAtProgramStart.currentSite,
          backupDestinationPath: settingsAtProgramStart.backupDestinationPath,
          workingDirectory: settingsAtProgramStart.appDirectoryPath,
          onCallback: (context, chars, error) => context.send(
            Response(
              String.fromCharCodes(chars),
              error ? Level.error : Level.normal,
            ),
          ),
        ),
      ],
    ),
    (response) {
      if (response.isError) {
        stderr.writeln(response.message);
        return;
      }
      stdout.writeln(response.message);
    },
  );

  if (lastResponse.isError) {
    return Response("Restore failed: ${lastResponse.message}", Level.critical);
  }

  return Response("Restore completed successfully.");
}

Future<Response> backupsListCommand(CommandInformation info) async {
  final String backupPath = settingsAtProgramStart.backupDestinationPath;
  final directory = Directory(backupPath);

  if (!directory.existsSync()) {
    return Response(
      "Backup directory does not exist: $backupPath",
      Level.warning,
    );
  }

  final List<FileSystemEntity> entities = directory
      .listSync()
      .whereType<Directory>()
      .toList();
  entities.sort(
    (a, b) => b.path.compareTo(a.path),
  ); // Sort by name descending (latest first)

  if (entities.isEmpty) {
    return Response("No backups found in $backupPath");
  }

  final StringBuffer buffer = StringBuffer();
  buffer.writeln("Available backups in $backupPath:");
  buffer.writeln("");

  for (final entity in entities) {
    if (entity is Directory) {
      final String name = path.basename(entity.path);
      final String frappeBackupsPath = path.join(entity.path, "backups");
      final String dockerVolumePath = path.join(
        entity.path,
        "erpnext_volumes_backup.tar.gz",
      );

      bool hasSql = false;
      bool hasFiles = false;
      bool hasPrivate = false;
      bool hasDocker = File(dockerVolumePath).existsSync();

      if (Directory(frappeBackupsPath).existsSync()) {
        final List<File> files = Directory(
          frappeBackupsPath,
        ).listSync().whereType<File>().toList();
        for (final file in files) {
          final fileName = path.basename(file.path);
          if (fileName.contains("-database.sql.gz")) hasSql = true;
          if (fileName.contains("-files.tgz")) hasFiles = true;
          if (fileName.contains("-private-files.tgz")) hasPrivate = true;
        }
      }

      // Only list if at least one component exists
      if (hasSql || hasFiles || hasPrivate || hasDocker) {
        final List<String> markers = [];
        markers.add(
          hasSql ? LogColor.green("SQL ✓") : LogColor.yellow("No SQL"),
        );
        markers.add(
          hasFiles ? LogColor.green("Files ✓") : LogColor.yellow("No Files"),
        );
        markers.add(
          hasPrivate
              ? LogColor.green("Private ✓")
              : LogColor.yellow("No Private"),
        );
        markers.add(
          hasDocker ? LogColor.green("Docker ✓") : LogColor.yellow("No Docker"),
        );

        buffer.writeln("- ${LogColor.cyan(name)} (${markers.join(", ")})");
      }
    }
  }

  return Response(buffer.toString());
}
