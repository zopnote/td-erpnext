import 'package:td_erpnext/src/steps/vendor/docker.dart';
import 'package:td_erpnext/src/utils.dart';

final class Execute extends DockerStep {
  final Container container;
  final String program;
  final List<String>? args;
  final bool interactive;
  final bool tty;
  final String? user;
  final String? innerContainerWorkingDirectory;
  final Map<String, String> environmentVariables;

  /// Executes a command in a running container.
  const Execute({
    super.callback,
    super.workingDirectory,
    super.programCallLiteral,
    required this.container,
    required this.program,
    this.args,
    this.interactive = false,
    this.tty = false,
    this.user,
    this.innerContainerWorkingDirectory,
    this.environmentVariables = const {},
  });

  @override
  List<String> format() => List.empty(growable: true)
    ..add("exec")
    ..addIf(interactive, "-i")
    ..addIf(tty, "-t")
    ..addAllNotNull(user, (v) => ["--user", v])
    ..addAllNotNull(innerContainerWorkingDirectory, (v) => ["--workdir", v])
    ..addAllIf(
      environmentVariables.entries.isNotEmpty,
      environmentVariables.entries.map((e) => ["-e", "${e.key}=${e.value}"]),
    )
    ..add(container.toString())
    ..addAll([program] + (args ?? []));
}
