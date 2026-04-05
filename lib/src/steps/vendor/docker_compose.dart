import 'dart:async';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
export 'package:td_erpnext/src/steps/vendor/docker_compose/init.dart';
export 'package:td_erpnext/src/steps/vendor/docker_compose/is_running.dart';
export 'package:td_erpnext/src/steps/vendor/docker_compose/shutdown.dart';
export 'package:td_erpnext/src/steps/vendor/docker_compose/stop.dart';

abstract class DockerComposeStep extends ConfigureStep {
  final OutputCallback? callback;
  final String? workingDirectory;
  final String? programCallLiteral;
  const DockerComposeStep({
    required this.callback,
    this.workingDirectory,
    this.programCallLiteral,
  });
  @override
  Step configure() => Shell(
    program: programCallLiteral ?? "docker-compose",
    arguments: format(),
    options: const ProcessInterfaceOptions(runAsAdministrator: true),
    onStdout: (chars) => callback?.call(chars, false),
    onStderr: (chars) => callback?.call(chars, true),
  );
  List<String> format();
}

typedef OutputCallback = FutureOr<void> Function(List<int> chars, bool isError);
