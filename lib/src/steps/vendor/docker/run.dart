import 'package:td_erpnext/src/steps/vendor/docker.dart';
import 'package:td_erpnext/src/utils.dart';

final class Run extends DockerStep {
  final Image image;
  final String program;
  final List<String>? args;
  final bool remove;
  final String? name;
  final List<Container> volumesFrom;
  final List<Volume> volumes;
  final Map<String, String> env;

  /// Runs a command in a new container.
  const Run({
    super.callback,
    super.workingDirectory,
    super.programCallLiteral,
    required this.image,
    required this.program,
    this.args,
    this.remove = false,
    this.name,
    this.volumesFrom = const [],
    this.volumes = const [],
    this.env = const {},
  });
  @override
  List<String> format() => List.empty(growable: true)
    ..add("run")
    ..addIf(remove, "--rm")
    ..addAllNotNull(name, (v) => ["--name", v])
    ..addAllIf(
      volumesFrom.isNotEmpty,
      volumesFrom.map((e) => ["--volumes-from", e.name]),
    )
    ..addAllIf(volumes.isNotEmpty, volumes.map((e) => ["-v", e.toString()]))
    ..addAllIf(
      env.entries.isNotEmpty,
      env.entries.map((e) => ["-e", "${e.key}=${e.value}"]),
    )
    ..add(image.toString())
    ..addAll([program] + (args ?? []));
}
