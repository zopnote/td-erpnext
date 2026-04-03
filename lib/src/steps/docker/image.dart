/// Represents a Docker Image.
class DockerImage {
  final String name;
  final String? tag;
  const DockerImage(this.name, {this.tag});

  @override
  String toString() => tag != null ? "$name:$tag" : name;

  static const DockerImage busybox = DockerImage("busybox");
}