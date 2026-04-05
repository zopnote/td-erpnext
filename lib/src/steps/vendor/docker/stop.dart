import 'package:td_erpnext/src/steps/vendor/docker.dart';
import 'package:td_erpnext/src/utils.dart';

final class Stop extends DockerStep {
  final List<Container> containers;
  final int? timeout;

  /// Stops one or more running containers.
  const Stop({
    super.callback,
    super.workingDirectory,
    super.programCallLiteral,
    required this.containers,
    this.timeout,
  });

  @override
  List<String> format() => List.empty(growable: true)
    ..add("stop")
    ..addAllNotNull(timeout, (v) => ["--time", v.toString()])
    ..addAll(containers.map((c) => c.name));
}
