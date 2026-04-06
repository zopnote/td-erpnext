import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

export 'package:td_erpnext/src/steps/vendor/docker/copy.dart';
export 'package:td_erpnext/src/steps/vendor/docker/execute.dart';
export 'package:td_erpnext/src/steps/vendor/docker/images.dart';
export 'package:td_erpnext/src/steps/vendor/docker/list.dart';
export 'package:td_erpnext/src/steps/vendor/docker/remove.dart';
export 'package:td_erpnext/src/steps/vendor/docker/run.dart';
export 'package:td_erpnext/src/steps/vendor/docker/start.dart';
export 'package:td_erpnext/src/steps/vendor/docker/stop.dart';
export 'package:td_erpnext/src/steps/vendor/docker/update.dart';

/// Callback signature for process output.
typedef OutputCallback = FutureOr<void> Function(List<int> chars);

abstract class DockerStep extends ConfigureStep {
  final OutputCallback? callback;
  final String? workingDirectory;
  final String? programCallLiteral;
  const DockerStep({
    this.callback,
    this.workingDirectory,
    this.programCallLiteral,
  });
  @override
  Step configure() => Shell(
    program: programCallLiteral ?? "docker",
    arguments: format(),
    options: const ProcessInterfaceOptions(runAsAdministrator: true),
    onStdout: (chars) => callback?.call(chars),
    onStderr: (chars) => callback?.call(chars),
  );
  List<String> format();
}

/// Represents a Docker Image.
class Image {
  final String name;
  final String? tag;
  const Image(this.name, {this.tag});

  @override
  String toString() => tag != null ? "$name:$tag" : name;

  static const Image busybox = Image("busybox");
}

/// Represents a Docker Container.
class Container {
  final String name;
  const Container(this.name);

  @override
  String toString() => name;
}

/// Represents a location in Docker (either host path or container path).
class Location {
  final Container? container;
  final String path;

  const Location.host(this.path) : container = null;
  const Location.container(this.container, this.path);

  @override
  String toString() => container != null ? "$container:$path" : path;
}

/// Represents a Docker Volume mapping (host:container).
class Volume {
  final String? volumeName;
  final String? hostPath;
  final String containerPath;

  const Volume({this.volumeName, this.hostPath, required this.containerPath});

  @override
  String toString() {
    if (volumeName != null) {
      return "$volumeName:$containerPath";

    }
    if (hostPath == null) {
      throw Exception("Specify either a volume name or an host path.");
    }
    return "${path.absolute(hostPath!)}:$containerPath";
  }

}
