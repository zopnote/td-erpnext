import 'package:td_erpnext/src/steps/vendor/docker.dart';

final class Copy extends DockerStep {
  final Location source;
  final Location destination;

  /// Copies files/folders between a container and the local filesystem.
  const Copy({
    super.callback,
    super.programCallLiteral,
    super.workingDirectory,
    required this.source,
    required this.destination,
  });
  @override
  List<String> format() => List.empty(growable: true)
    ..add("cp")
    ..add(source.toString())
    ..add(destination.toString());
}
