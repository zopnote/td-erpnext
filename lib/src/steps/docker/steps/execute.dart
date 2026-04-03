import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/docker/docker.dart';


final class ExecSettings with StepWiser<Docker, ExecSettings, Exec> {
  final DockerContainer container;
  final String program;
  final List<String>? args;
  final DockerExecConfig config;
  const ExecSettings({
    required this.container,
    required this.program,
    this.args,
    this.config = const DockerExecConfig(),
  });
  @override
  Exec create() => Exec();
}

final class Exec extends DockerStep<ExecSettings> {
  @override
  List<String> format() => List.empty(growable: true)
    ..add("exec")
    ..addIf(wise.config.interactive, "-i")
    ..addIf(wise.config.tty, "-t")
    ..addAllNotNull(wise.config.user, (v) => ["--user", v])
    ..addAllNotNull(wise.config.workingDirectory, (v) => ["--workdir", v])
    ..addAllIf(
      wise.config.env.entries.isNotEmpty,
      wise.config.env.entries.map((e) => ["-e", "${e.key}=${e.value}"]),
    )
    ..add(wise.container.toString())
    ..addAll([wise.program] + (wise.args ?? []));
}
