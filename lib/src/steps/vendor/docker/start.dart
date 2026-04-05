import 'package:td_erpnext/src/steps/vendor/docker.dart';

final class Start extends DockerStep {
  final List<Container> containers;

  /// Starts one or more stopped containers.
  const Start({
    super.callback,
    super.workingDirectory,
    super.programCallLiteral,
    required this.containers,
  });
  @override
  List<String> format() => List.empty(growable: true)
    ..add("start")
    ..addAll(containers.map((c) => c.name));
}
