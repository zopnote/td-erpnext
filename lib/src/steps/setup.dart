import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:stepflow/io.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/utils.dart';

class SetupException implements Exception {
  const SetupException(this.message);
  final String message;
  static SetupException dockerCompose(String error) => SetupException(
    "An unexpected error occurred inside "
    "docker compose while setup of the erpnext "
    "installation: $error",
  );
  static SetupException unavailableDependencies(List<String> dependencies) {
    return SetupException(
      "The following dependencies aren't satisfied: ${dependencies.join(", ")}. ",
    );
  }

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (other is! SetupException) {
      return false;
    }
    return other.message == message;
  }
}

class Setup extends ConfigureStep {
  const Setup();

  @override
  Step configure() {
    final File composeFile = File(
      path.join(Settings.appDirectoryPath, "frappe_docker", "pwd.yml"),
    );
    final Directory repository = Directory(
      path.join(Settings.appDirectoryPath, "frappe_docker"),
    );
    return Chain(
      steps: [
        Check(
          programs: ["docker", "git", "systemctl", "systemd"],
          onFailure: (programs) =>
              throw SetupException.unavailableDependencies(programs),
        ),
        Conditional(
          condition: !repository.existsSync(),
          child: Chain(
            steps: [
              CreateDirectory(
                Settings.appDirectoryPath,
                recursive: true,
                deleteIfExists: true,
              ),
              Shell(
                program: "git",
                arguments: ["clone", "https://github.com/frappe/frappe_docker"],
                options: ProcessInterfaceOptions(
                  workingDirectory: Settings.appDirectoryPath,
                ),
              ),
            ],
          ),
        ),
        dockerCompose.Init(
          composeFile: composeFile,
          detach: true,
          workingDirectory: Settings.appDirectoryPath,
          callback: (chars, isError) {
            if (isError) {
              throw SetupException.dockerCompose(String.fromCharCodes(chars));
            }
          },
        ),
      ],
    );
  }
}
