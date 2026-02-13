import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:stepflow/io.dart';
import 'package:stepflow/core.dart';

/// Callback signature for process output.
typedef DockerOutputCallback = FutureOr<void> Function(FlowContext context, List<int> chars);

/// Represents a Docker Image.
class DockerImage {
  final String name;
  final String? tag;
  const DockerImage(this.name, {this.tag});

  @override
  String toString() => tag != null ? "$name:$tag" : name;

  static const DockerImage busybox = DockerImage("busybox");
}

/// Represents a Docker Container.
class DockerContainer {
  final String name;
  const DockerContainer(this.name);

  @override
  String toString() => name;
}

/// Represents a Docker Volume mapping (host:container).
class DockerVolume {
  final String hostPath;
  final String containerPath;

  const DockerVolume({required this.hostPath, required this.containerPath});

  @override
  String toString() => "${path.absolute(hostPath)}:$containerPath";
}

/// Represents a location in Docker (either host path or container path).
class DockerLocation {
  final DockerContainer? container;
  final String path;

  const DockerLocation.host(this.path) : container = null;
  const DockerLocation.container(this.container, this.path);

  @override
  String toString() => container != null ? "$container:$path" : path;
}

/// Settings for the `docker run` command.
class DockerRunSettings {
  final bool remove;
  final String? name;
  final List<DockerContainer> volumesFrom;
  final List<DockerVolume> volumes;
  final Map<String, String> environment;

  const DockerRunSettings({
    this.remove = false,
    this.name,
    this.volumesFrom = const [],
    this.volumes = const [],
    this.environment = const {},
  });
}

/// Settings for the `docker exec` command.
class DockerExecSettings {
  final bool interactive;
  final bool tty;
  final String? user;
  final String? workingDirectory;
  final Map<String, String> environment;

  const DockerExecSettings({
    this.interactive = false,
    this.tty = false,
    this.user,
    this.workingDirectory,
    this.environment = const {},
  });
}

/// Main entry point for Docker commands.
class Docker {
  const Docker();

  /// Executes a command in a running container.
  static Step execute({
    required DockerContainer container,
    required String program,
    List<String>? arguments,
    DockerExecSettings settings = const DockerExecSettings(),
    bool runAsAdministrator = false,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    final List<String> args = ["exec"];
    if (settings.interactive) args.add("-i");
    if (settings.tty) args.add("-t");
    if (settings.user != null) args.addAll(["--user", settings.user!]);
    if (settings.workingDirectory != null) {
      args.addAll(["--workdir", settings.workingDirectory!]);
    }
    for (final entry in settings.environment.entries) {
      args.addAll(["-e", "${entry.key}=${entry.value}"]);
    }
    args.add(container.toString());
    args.addAll([program] + (arguments ?? []));

    return Shell(
      program: "docker",
      arguments: args,
      options: ProcessInterfaceOptions(runAsAdministrator: runAsAdministrator),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }

  /// Copies files/folders between a container and the local filesystem.
  static Step copy({
    required DockerLocation source,
    required DockerLocation destination,
    bool runAsAdministrator = false,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    return Shell(
      program: "docker",
      arguments: ["cp", source.toString(), destination.toString()],
      options: ProcessInterfaceOptions(runAsAdministrator: runAsAdministrator),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }

  /// Starts one or more stopped containers.
  static Step start({
    required List<DockerContainer> containers,
    bool runAsAdministrator = false,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    return Shell(
      program: "docker",
      arguments: ["start", ...containers.map((c) => c.toString())],
      options: ProcessInterfaceOptions(runAsAdministrator: runAsAdministrator),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }

  /// Stops one or more running containers.
  static Step stop({
    required List<DockerContainer> containers,
    int? timeout,
    bool runAsAdministrator = false,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    final List<String> arguments = ["stop"];
    if (timeout != null) arguments.addAll(["--time", timeout.toString()]);
    arguments.addAll(containers.map((c) => c.toString()));

    return Shell(
      program: "docker",
      arguments: arguments,
      options: ProcessInterfaceOptions(runAsAdministrator: runAsAdministrator),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }

  /// Removes one or more containers.
  static Step remove({
    required List<DockerContainer> containers,
    bool force = false,
    bool volumes = false,
    bool runAsAdministrator = false,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    final List<String> arguments = ["rm"];
    if (force) arguments.add("--force");
    if (volumes) arguments.add("--volumes");
    arguments.addAll(containers.map((c) => c.toString()));

    return Shell(
      program: "docker",
      arguments: arguments,
      options: ProcessInterfaceOptions(runAsAdministrator: runAsAdministrator),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }

  /// Lists containers.
  static Step list({
    bool all = false,
    bool runAsAdministrator = false,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    final List<String> arguments = ["ps"];
    if (all) arguments.add("-a");

    return Shell(
      program: "docker",
      arguments: arguments,
      options: ProcessInterfaceOptions(runAsAdministrator: runAsAdministrator),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }

  /// Lists images.
  static Step images({
    bool all = false,
    bool runAsAdministrator = false,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    final List<String> arguments = ["images"];
    if (all) arguments.add("-a");

    return Shell(
      program: "docker",
      arguments: arguments,
      options: ProcessInterfaceOptions(runAsAdministrator: runAsAdministrator),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }

  /// Runs a command in a new container.
  static Step run({
    required DockerImage image,
    required String program,
    List<String>? arguments,
    DockerRunSettings settings = const DockerRunSettings(),
    bool runAsAdministrator = false,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    final List<String> args = ["run"];
    if (settings.remove) args.add("--rm");
    if (settings.name != null) args.addAll(["--name", settings.name!]);
    for (final v in settings.volumesFrom) {
      args.addAll(["--volumes-from", v.toString()]);
    }
    for (final v in settings.volumes) {
      args.addAll(["-v", v.toString()]);
    }
    for (final entry in settings.environment.entries) {
      args.addAll(["-e", "${entry.key}=${entry.value}"]);
    }
    args.add(image.toString());
    args.addAll([program] + (arguments ?? []));

    return Shell(
      program: "docker",
      arguments: args,
      options: ProcessInterfaceOptions(runAsAdministrator: runAsAdministrator),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }
}

/// Entry point for Docker Compose commands.
class DockerCompose {
  const DockerCompose();

  /// Starts the containers defined in the compose file.
  static Step setup({
    File? composeFile,
    String? projectName,
    bool detach = false,
    bool build = false,
    bool runAsAdministrator = false,
    String? workingDirectory,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    final List<String> arguments = ["compose"];
    if (composeFile != null) {
      arguments.addAll(["-f", path.basename(composeFile.path)]);
    }
    if (projectName != null) {
      arguments.addAll(["-p", projectName]);
    }
    arguments.add("up");
    if (detach) arguments.add("-d");
    if (build) arguments.add("--build");

    return Shell(
      program: "docker",
      arguments: arguments,
      options: ProcessInterfaceOptions(
        runAsAdministrator: runAsAdministrator,
        workingDirectory:
            workingDirectory ??
            (composeFile != null ? path.dirname(composeFile.path) : null),
      ),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }

  /// Stops and removes containers, networks, images, and volumes.
  static Step delete({
    required File? composeFile,
    required String? projectName,
    bool removeVolumes = false,
    bool removeImages = false,
    bool runAsAdministrator = false,
    DockerOutputCallback? onStdout,
    DockerOutputCallback? onStderr,
  }) {
    final List<String> arguments = ["compose"];
    if (composeFile != null) {
      arguments.addAll(["-f", path.basename(composeFile.path)]);
    }
    arguments.add("down");
    if (removeVolumes) arguments.add("-v");
    if (removeImages) arguments.addAll(["--rmi", "all"]);

    return Shell(
      program: "docker",
      arguments: arguments,
      options: ProcessInterfaceOptions(
        runAsAdministrator: runAsAdministrator,
        workingDirectory: composeFile != null
            ? path.dirname(composeFile.path)
            : null,
      ),
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }
}
