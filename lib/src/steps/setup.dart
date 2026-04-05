import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:stepflow/io.dart';
import 'package:stepflow/core.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/settings.dart';

import 'package:td_erpnext/src/steps/create_directory.dart';
import 'package:td_erpnext/src/steps/docker_compose/docker_compose.dart';

import 'docker/docker.dart';

class Setup extends ConfigureStep {
  const Setup();

  @override
  Step configure() {
    final String composeFilePath = path.join(
      Settings.appDirectoryPath,
      "frappe_docker",
      "pwd.yml",
    );
    final Directory repository = Directory(
      path.join(Settings.appDirectoryPath, "frappe_docker"),
    );
    final DockerCompose dockerCompose = DockerCompose(
      onCallback: (context, chars, isError) {
        if (isError) {
          throw;
        }
      }
    );
    return Chain(
      steps: [
        Check(
          programs: ["docker", "git", "systemctl", "systemd"],
          onFailure: (context, programs) => context.pop(
            "The following dependencies aren't satisfied: ${programs.join(", ")}. ",
          ),
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
                onStdout: (context, chars) =>
                    _grayedCallback.call(context, chars, false),
                onStderr: (context, chars) =>
                    _grayedCallback.call(context, chars, true),
              ),
            ],
          ),
        ),
        .init(
          composeFile: File(composeFilePath),
          workingDirectory: appDirectoryPath,
          detach: true,
          onCallback: _grayedCallback,
        ),
      ],
    );
  }
}
