import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/steps/docker_compose/steps/init.dart';
import 'package:td_erpnext/src/steps/docker_compose/steps/shutdown.dart';

import '../docker/docker.dart' as docker;
import 'steps/stop.dart';

export 'steps/init.dart';
export 'steps/shutdown.dart';
export 'steps/stop.dart';

abstract class DockerComposeStep<
  Wiser
      extends StepWiser<DockerCompose, Wiser, SingleStep<DockerCompose, Wiser>>
>
    extends SingleStep<DockerCompose, Wiser> {
  @override
  Step configure() => Shell(
    program: step.programCallLiteral,
    arguments: format(),
    options: const ProcessInterfaceOptions(runAsAdministrator: true),
    onStdout: (context, chars) => step.onCallback?.call(context, chars, false),
    onStderr: (context, chars) => step.onCallback?.call(context, chars, true),
  );
  List<String> format();
}

/// Entry point for Docker Compose commands.
final class DockerCompose extends CollectionStep<DockerCompose> {
  const DockerCompose({
    this.onCallback,
    this.programCallLiteral = "docker-compose",
  });
  final docker.DockerOutputCallback? onCallback;
  final String programCallLiteral;

  /// Starts the containers defined in the compose file.
  Step init(InitSettings settings) => stepwise<Init, InitSettings>(settings);

  /// Stops the containers defined in the compose file without removing them.
  Step stop(StopSettings settings) => stepwise<Stop, StopSettings>(settings);

  /// Stops and/or removes containers, networks, images, and volumes.
  Step shutdown(ShutdownSettings settings) =>
      stepwise<Shutdown, ShutdownSettings>(settings);
}
