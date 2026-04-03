import 'container.dart';

/// Represents a location in Docker (either host path or container path).
class DockerLocation {
  final DockerContainer? container;
  final String path;

  const DockerLocation.host(this.path) : container = null;
  const DockerLocation.container(this.container, this.path);

  @override
  String toString() => container != null ? "$container:$path" : path;
}