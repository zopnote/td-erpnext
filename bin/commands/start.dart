
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/docker.dart';

Future<Response> startCommand(CommandInformation info) async {
  if (info.getFlag("help").value) {
    return Response(info.command.formatSyntax(spacer: 13), Level.normal);
  }
  final Settings settings = Settings.load();
  await runWorkflow(
    StartWorkflow(settings: settings),
        (response) {
      if (response.isError) {
        stderr.writeln(response.message);
        return;
      }
      stdout.writeln(response.message);
    },
  );
  return const Response();
}

class StartWorkflow extends ConfigureStep {
  final Settings settings;

  const StartWorkflow({required this.settings});

  @override
  Step configure() {
    final String composeFilePath = path.join(
      settings.appDirectoryPath,
      "frappe_docker",
      "pwd.yml",
    );
    return Chain(steps: [
      DockerCompose.init(
        composeFile: File(composeFilePath),
        workingDirectory: settings.appDirectoryPath,
        detach: true,
        onCallback: (context, chars, error) => context.send(
          Response(
            String.fromCharCodes(chars),
            error ? Level.error : Level.normal,
          ),
        ),
      )
    ]);
  }
}