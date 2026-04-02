import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/docker.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/settings.dart';

class ERPNextRestore extends ConfigureStep {
  final DockerContainer container;
  final String currentSiteName;
  final String backupsDirectoryPath;
  final String workingDirectory;
  final String appDirectoryPath;
  final bool restoreLast;
  final String? backupBundleName;
  final DockerOutputCallback? onCallback;

  ERPNextRestore({
    this.restoreLast = false,
    this.backupBundleName,
    required this.container,
    required this.currentSiteName,
    required this.onCallback,
    required this.backupsDirectoryPath,
    required this.appDirectoryPath,
    required this.workingDirectory,
  });

  late final String composeFilePath = path.join(
    appDirectoryPath,
    "frappe_docker",
    "pwd.yml",
  );
  late final DockerOutputCallback _grayedCallback = (context, chars, error) =>
      this.onCallback?.call(
        context,
        LogColor.grayed(String.fromCharCodes(chars)).codeUnits,
        error,
      );

  static String? _getFile(String endsWith, Directory directory) {
    final List<File> files = directory
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(endsWith))
        .toList();
    return files.isNotEmpty ? files.first.path : null;
  }

  @override
  Step configure() {
    if (restoreLast && backupBundleName != null) {
      return const LogASCIIContext(
        "You can't restore the last bundle and provide a specific bundle to restore at the same time. Decide for one use case.",
        level: Level.error,
      );
    }

    String backupBundlePath = backupBundleName != null
        ? path.join(backupsDirectoryPath, backupBundleName)
        : "";

    if (!Directory(backupBundlePath).existsSync() && backupBundleName != null) {
      return LogASCIIContext(
        "The backup bundle ${backupBundlePath} doesn't exist.",
        level: Level.error,
      );
    }
    /**
     * List all backup bundles under [backupsDirectoryPath].
     *
     * These bundles are saved with ISO-date-standard.
     * E.g. 2026-02-14T23_14_2, 2026-02-14T23_09_3...
     */
    if (backupBundlePath.isEmpty) {
      final backupsDirectory = Directory(backupsDirectoryPath);
      if (backupsDirectory.existsSync()) {
        final List<FileSystemEntity> entities =
            backupsDirectory.listSync().whereType<Directory>().toList()..sort(
              // Sort by name descending (ISO date)
              (a, b) => b.path.compareTo(a.path),
            );
        if (entities.isNotEmpty) {
          backupBundlePath = entities.first.path;
        }
      }
    }

    if (backupBundlePath.isEmpty) {
      return LogASCIIContext(
        "No backups found at $backupsDirectoryPath.",
        level: Level.error,
      );
    }

    final backupBundleBenchPath = Directory(
      path.join(backupBundlePath, "backups"),
    );

    final String? sqlFile = _getFile(".sql.gz", backupBundleBenchPath);

    final String? privateFile = _getFile(
      "private-files.tgz",
      backupBundleBenchPath,
    );

    final String? publicFile = _getFile(
      "$currentSiteName-files.tgz",
      backupBundleBenchPath,
    );

    stdout.write("""
Selected backup ${LogColor.cyanid(path.basename(backupBundlePath))}
SQL file: ${sqlFile != null ? LogColor.greened("✓ Found") : LogColor.redid("✕ Not found")}
Private file: ${privateFile != null ? LogColor.greened("✓ Found") : LogColor.redid("✕ Not found")}
Public file: ${publicFile != null ? LogColor.greened("✓ Found") : LogColor.redid("✕ Not found")}

Start to restore backup...
""");
    final String restorableBackupsPathOnContainer = "/home/frappe/restorable/";

    final Settings settings = Settings.load();
    return Chain(
      steps: [
        LogASCIIContext("Stop containers..."),
        // 1. Stop containers before restoring volumes
        DockerCompose.stop(
          composeFile: File(composeFilePath),
          workingDirectory: workingDirectory,
          onCallback: _grayedCallback,
        ),
        // 2. Cleanup old volumes
        LogASCIIContext("Cleaning up old volumes..."),
        Docker.run(
          image: DockerImage.busybox,
          program: "rm",
          arguments: ["-r", "-f", "/home/frappe/frappe-bench/**/**"],
          settings: DockerRunSettings(remove: true, volumesFrom: [container]),
          onCallback: _grayedCallback,
        ),
        // Restore Volumes
        LogASCIIContext("Restore volume..."),
        Docker.run(
          image: DockerImage.busybox,
          program: "tar",
          arguments: [
            "-xvzf",
            "backup/erpnext_volumes_backup.tar.gz",
            "-C",
            "/",
          ],
          settings: DockerRunSettings(
            remove: true,
            volumesFrom: [container],
            volumes: [
              DockerVolume(
                hostPath: backupBundlePath,
                containerPath: "/backup",
              ),
            ],
          ),
          onCallback: _grayedCallback,
        ),
        LogASCIIContext("Restart container..."),
        // 3. Start containers again
        DockerCompose.init(
          composeFile: File(composeFilePath),
          workingDirectory: workingDirectory,
          detach: true,
          onCallback: _grayedCallback,
        ),
        // 4. Restore bench backup (to fix potential DB corruption)
        Conditional(
          condition:
              sqlFile != null || privateFile != null || publicFile != null,
          child: Chain(
            steps: [
              LogASCIIContext("Restore bench files..."),
              // Create directory in container if not exists
              Docker.execute(
                container: container,
                program: "mkdir",
                arguments: ["-p", restorableBackupsPathOnContainer],
                settings: const DockerExecSettings(user: "frappe"),
              ),
              // Copy the SQL file back to container
              Conditional(
                condition: sqlFile != null,
                child: Chain(
                  steps: [
                    LogASCIIContext("Restore sql file..."),
                    Docker.copy(
                      source: DockerLocation.host(sqlFile ?? ""),
                      destination: DockerLocation.container(
                        container,
                        restorableBackupsPathOnContainer,
                      ),
                      onCallback: _grayedCallback,
                    ),
                  ],
                ),
              ),
              Conditional(
                condition: privateFile != null,
                child: Chain(
                  steps: [
                    LogASCIIContext("Restore private file..."),
                    Docker.copy(
                      source: DockerLocation.host(privateFile ?? ""),
                      destination: DockerLocation.container(
                        container,
                        restorableBackupsPathOnContainer,
                      ),
                      onCallback: _grayedCallback,
                    ),
                  ],
                ),
              ),
              Conditional(
                condition: publicFile != null,
                child: Chain(
                  steps: [
                    LogASCIIContext("Restore public file..."),
                    Docker.copy(
                      source: DockerLocation.host(publicFile ?? ""),
                      destination: DockerLocation.container(
                        container,
                        restorableBackupsPathOnContainer,
                      ),
                      onCallback: _grayedCallback,
                    ),
                  ],
                ),
              ),
              // Run bench restore
              Docker.execute(
                container: container,
                program: "bench",
                arguments: [
                  "--site",
                  currentSiteName,
                  "--force",
                  "restore",
                  path.join(
                    restorableBackupsPathOnContainer,
                    path.basename(sqlFile ?? ""),
                  ),
                  if (settings.dbRootPassword.value.isNotEmpty) ...[
                    "--mariadb-root-password",
                    settings.dbRootPassword.value,
                  ],
                  "--with-private-files",
                  path.join(
                    restorableBackupsPathOnContainer,
                    path.basename(privateFile ?? ""),
                  ),
                  "--with-public-files",
                  path.join(
                    restorableBackupsPathOnContainer,
                    path.basename(publicFile ?? ""),
                  ),
                ],
                onCallback: _grayedCallback,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
