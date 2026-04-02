import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:stepflow/io.dart';
import 'package:stepflow/core.dart';
import 'package:stepflow/src/io/steps/log_print.dart';

import 'package:td_erpnext/src/package:td_erpnext/src/#/create_directory.dart';
import 'package:td_erpnext/src/steps/docker.dart';

class ERPNextSetup extends ConfigureStep {
  final DockerOutputCallback? onCallback;
  final String appDirectoryPath;

  ERPNextSetup._internal({this.onCallback, required this.appDirectoryPath});

  factory ERPNextSetup({
    DockerOutputCallback? onCallback,
    required String appDirectoryPath,
  }) {
    return ERPNextSetup._internal(
      onCallback: onCallback,
      appDirectoryPath: appDirectoryPath,
    );
  }

  late final DockerOutputCallback _grayedCallback = (context, chars, error) =>
      this.onCallback?.call(
        context,
        LogColor.grayed(String.fromCharCodes(chars)).codeUnits,
        error,
      );

  @override
  Step configure() {
    final String composeFilePath = path.join(
      appDirectoryPath,
      "frappe_docker",
      "pwd.yml",
    );
    final Directory repository = Directory(
      path.join(appDirectoryPath, "frappe_docker"),
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
                onStdout: (context, chars) =>
                    _grayedCallback.call(context, chars, false),
                onStderr: (context, chars) =>
                    _grayedCallback.call(context, chars, true),
              ),
            ],
          ),
        ),
        DockerCompose.init(
          composeFile: File(composeFilePath),
          workingDirectory: appDirectoryPath,
          detach: true,
          onCallback: _grayedCallback,
        ),
      ],
    );
  }
}
