import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/io.dart';
import 'package:stepflow/core.dart';
import 'package:yaml/yaml.dart';
import 'docker.dart';

class ManagerWorkflow extends ConfigureStep {
  final String rootDirectoryPath;
  final String confDirectoryPath;
  final String binDirectoryPath;
  final DockerOutputCallback? onStdout;
  final DockerOutputCallback? onStderr;

  const ManagerWorkflow._internal({
    required this.rootDirectoryPath,
    required this.confDirectoryPath,
    required this.binDirectoryPath,
    this.onStdout,
    this.onStderr,
  });

  static ManagerWorkflow binaries({
    required final String rootDirectoryPath,
    required String binDirectoryName,
    required String confDirectoryName,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    return ManagerWorkflow._internal(
      rootDirectoryPath: rootDirectoryPath,
      confDirectoryPath: path.join(rootDirectoryPath, confDirectoryName),
      binDirectoryPath: path.join(rootDirectoryPath, binDirectoryName),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }

  @override
  Step configure() {
    final File paths = File(path.join(confDirectoryPath, "paths.yaml"));
    final Map<dynamic, dynamic> pathsDocument = loadYaml(
      paths.readAsStringSync(),
    );

    final File settings = File(path.join(confDirectoryPath, "settings.yaml"));
    final Map<dynamic, dynamic> settingsDocument = loadYaml(
      settings.readAsStringSync(),
    );

    final DockerContainer backendContainer = DockerContainer(
      settingsDocument["parameter"]["docker_frappe_backend_container_name"],
    );
    final String backupPath = pathsDocument["backup_directory"];
    final String currentSite =
        settingsDocument["parameter"]["erpnext_site_name"];

    final String appDirectoryPath = path.join(
      rootDirectoryPath,
      pathsDocument["app_directory"],
    );
    return Chain(
      steps: [
        Check(
          programs: ["docker", "git", "systemctl"],
          onFailure: (context, programs) => context.pop(
            "The following dependencies aren't satisfied: ${programs.join(", ")}. ",
          ),
        ),
        Conditional(
          condition: !Directory(
            path.join(appDirectoryPath, "frappe_docker"),
          ).existsSync(),
          child: Chain(
            steps: [
              CreateDirectory(
                appDirectoryPath,
                recursive: true,
                deleteIfExists: true,
              ),
              Shell(
                program: "git",
                arguments: ["clone", "https://github.com/frappe/frappe_docker"],
                options: ProcessInterfaceOptions(
                  workingDirectory: appDirectoryPath,
                ),
                onStdout: onStdout,
                onStderr: onStderr,
              ),
            ],
          ),
        ),
        DockerCompose.setup(
          composeFile: File(
            path.join(appDirectoryPath, "frappe_docker", "pwd.yml"),
          ),
          detach: true,
          runAsAdministrator: true,
          onStdout: onStdout,
          onStderr: onStderr,
        ),
        Conditional(
          condition: settingsDocument["do_backups"],
          child: Chain(
            steps: [
              Docker.execute(
                container: backendContainer,
                program: "bench",
                arguments: ["backup", "--all"],
                runAsAdministrator: true,
                onStdout: onStdout,
                onStderr: onStderr,
              ),
              Docker.copy(
                source: DockerLocation.container(
                  backendContainer,
                  "/home/frappe/frappe-bench/sites/$currentSite/private/backups",
                ),
                destination: DockerLocation.host(backupPath),
                runAsAdministrator: true,
                onStdout: onStdout,
                onStderr: onStderr,
              ),
              Docker.run(
                image: DockerImage.busybox,
                program: "tar",
                arguments: [
                  "-cvzf",
                  "/backup/erpnext_volumes_backup.tar.gz",
                  "/home/frappe/frappe-bench/sites",
                ],
                settings: DockerRunSettings(
                  remove: true,
                  volumesFrom: [backendContainer],
                  volumes: [
                    DockerVolume(
                      hostPath: path.absolute(backupPath),
                      containerPath: "/backup",
                    ),
                  ],
                ),
                runAsAdministrator: true,
                onStdout: onStdout,
                onStderr: onStderr,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CreateDirectory extends ConfigureStep {
  final String path;
  final bool recursive;
  final bool deleteIfExists;
  const CreateDirectory(
    this.path, {
    this.recursive = false,
    this.deleteIfExists = false,
  });
  @override
  Step configure() => Runnable((context) async {
    final bool exists = await Directory(path).exists();
    if (exists) {
      if (!deleteIfExists) {
        return;
      }
      await Directory(path).delete(recursive: true);
    }
    await Directory(path).create(recursive: recursive);
  });
}
