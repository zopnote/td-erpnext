import 'package:path/path.dart' as path;

/// Represents a Docker Volume mapping (host:container).
class DockerVolume {
  final String hostPath;
  final String containerPath;

  const DockerVolume({required this.hostPath, required this.containerPath});

  @override
  String toString() => "${path.absolute(hostPath)}:$containerPath";
}
