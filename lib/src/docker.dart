import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:stepflow/io.dart';
import 'package:stepflow/core.dart';

/// Callback signature for process output.
typedef DockerOutputCallback =
    FutureOr<void> Function(FlowContext context, List<int> chars, bool isError);

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

/// Possible Docker restart policies.
enum DockerRestartPolicy {
  no,
  always,
  unlessStopped,
  onFailure;

  @override
  String toString() {
    switch (this) {
      case DockerRestartPolicy.no:
        return "no";
      case DockerRestartPolicy.always:
        return "always";
      case DockerRestartPolicy.unlessStopped:
        return "unless-stopped";
      case DockerRestartPolicy.onFailure:
        return "on-failure";
    }
  }
}

/// Settings for the `docker update` command.
class DockerUpdateSettings {
  final int? blkioWeight;
  final int? cpuPeriod;
  final int? cpuQuota;
  final int? cpuRealtimePeriod;
  final int? cpuRealtimeRuntime;
  final int? cpuShares;
  final double? cpus;
  final String? cpuSetCpus;
  final String? cpuSetMems;
  final String? memory;
  final String? memoryReservation;
  final String? memorySwap;
  final DockerRestartPolicy? restart;

  const DockerUpdateSettings({
    this.blkioWeight,
    this.cpuPeriod,
    this.cpuQuota,
    this.cpuRealtimePeriod,
    this.cpuRealtimeRuntime,
    this.cpuShares,
    this.cpus,
    this.cpuSetCpus,
    this.cpuSetMems,
    this.memory,
    this.memoryReservation,
    this.memorySwap,
    this.restart,
  });
}

/// Main entry point for Docker commands.
class Docker {
  const Docker._internal();

  /// Executes a command in a running container.
  static Step execute({
    required DockerContainer container,
    required String program,
    List<String>? arguments,
    DockerExecSettings settings = const DockerExecSettings(),
    DockerOutputCallback? onCallback,
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
      options: const ProcessInterfaceOptions(runAsAdministrator: true),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Copies files/folders between a container and the local filesystem.
  static Step copy({
    required DockerLocation source,
    required DockerLocation destination,
    DockerOutputCallback? onCallback,
  }) {
    return Shell(
      program: "docker",
      arguments: ["cp", source.toString(), destination.toString()],
      options: const ProcessInterfaceOptions(runAsAdministrator: true),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Starts one or more stopped containers.
  static Step start({
    required List<DockerContainer> containers,
    DockerOutputCallback? onCallback,
  }) {
    return Shell(
      program: "docker",
      arguments: ["start", ...containers.map((c) => c.toString())],
      options: const ProcessInterfaceOptions(runAsAdministrator: true),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Stops one or more running containers.
  static Step stop({
    required List<DockerContainer> containers,
    int? timeout,
    DockerOutputCallback? onCallback,
  }) {
    final List<String> arguments = ["stop"];
    if (timeout != null) arguments.addAll(["--time", timeout.toString()]);
    arguments.addAll(containers.map((c) => c.toString()));

    return Shell(
      program: "docker",
      arguments: arguments,
      options: const ProcessInterfaceOptions(runAsAdministrator: true),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Removes one or more containers.
  static Step remove({
    required List<DockerContainer> containers,
    bool force = false,
    bool volumes = false,
    DockerOutputCallback? onCallback,
  }) {
    final List<String> arguments = ["rm"];
    if (force) arguments.add("--force");
    if (volumes) arguments.add("--volumes");
    arguments.addAll(containers.map((c) => c.toString()));

    return Shell(
      program: "docker",
      arguments: arguments,
      options: const ProcessInterfaceOptions(runAsAdministrator: true),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Lists containers.
  static Step list({bool all = false, DockerOutputCallback? onCallback}) {
    final List<String> arguments = ["ps"];
    if (all) arguments.add("-a");

    return Shell(
      program: "docker",
      arguments: arguments,
      options: const ProcessInterfaceOptions(runAsAdministrator: true),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Lists images.
  static Step images({bool all = false, DockerOutputCallback? onCallback}) {
    final List<String> arguments = ["images"];
    if (all) arguments.add("-a");

    return Shell(
      program: "docker",
      arguments: arguments,
      options: const ProcessInterfaceOptions(runAsAdministrator: true),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Updates configuration of one or more containers.
  static Step update({
    required List<DockerContainer> containers,
    DockerUpdateSettings settings = const DockerUpdateSettings(),
    DockerOutputCallback? onCallback,
  }) {
    final List<String> args = ["update"];
    if (settings.blkioWeight != null) {
      args.addAll(["--blkio-weight", settings.blkioWeight.toString()]);
    }
    if (settings.cpuPeriod != null) {
      args.addAll(["--cpu-period", settings.cpuPeriod.toString()]);
    }
    if (settings.cpuQuota != null) {
      args.addAll(["--cpu-quota", settings.cpuQuota.toString()]);
    }
    if (settings.cpuRealtimePeriod != null) {
      args.addAll(["--cpu-rt-period", settings.cpuRealtimePeriod.toString()]);
    }
    if (settings.cpuRealtimeRuntime != null) {
      args.addAll(["--cpu-rt-runtime", settings.cpuRealtimeRuntime.toString()]);
    }
    if (settings.cpuShares != null) {
      args.addAll(["--cpu-shares", settings.cpuShares.toString()]);
    }
    if (settings.cpus != null) {
      args.addAll(["--cpus", settings.cpus.toString()]);
    }
    if (settings.cpuSetCpus != null) {
      args.addAll(["--cpuset-cpus", settings.cpuSetCpus!]);
    }
    if (settings.cpuSetMems != null) {
      args.addAll(["--cpuset-mems", settings.cpuSetMems!]);
    }
    if (settings.memory != null) {
      args.addAll(["--memory", settings.memory!]);
    }
    if (settings.memoryReservation != null) {
      args.addAll(["--memory-reservation", settings.memoryReservation!]);
    }
    if (settings.memorySwap != null) {
      args.addAll(["--memory-swap", settings.memorySwap!]);
    }
    if (settings.restart != null) {
      args.addAll(["--restart", settings.restart.toString()]);
    }
    args.addAll(containers.map((c) => c.toString()));

    return Shell(
      program: "docker",
      arguments: args,
      options: const ProcessInterfaceOptions(runAsAdministrator: true),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Runs a command in a new container.
  static Step run({
    required DockerImage image,
    required String program,
    List<String>? arguments,
    DockerRunSettings settings = const DockerRunSettings(),
    DockerOutputCallback? onCallback,
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
      options: const ProcessInterfaceOptions(runAsAdministrator: true),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }
}

/// Entry point for Docker Compose commands.
class DockerCompose {
  const DockerCompose._internal();

  /// Starts the containers defined in the compose file.
  static Step init({
    File? composeFile,
    String? projectName,
    bool detach = false,
    bool build = false,
    String? workingDirectory,
    DockerOutputCallback? onCallback,
  }) {
    final List<String> arguments = [];
    if (composeFile != null) {
      arguments.addAll(["-f", composeFile.path]);
    }
    if (projectName != null) {
      arguments.addAll(["-p", projectName]);
    }
    arguments.add("up");
    if (detach) arguments.add("-d");
    if (build) arguments.add("--build");

    return Shell(
      program: "docker-compose",
      arguments: arguments,
      options: ProcessInterfaceOptions(
        runAsAdministrator: true,
        workingDirectory: workingDirectory,
      ),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Stops the containers defined in the compose file without removing them.
  static Step stop({
    File? composeFile,
    String? projectName,
    String? workingDirectory,
    DockerOutputCallback? onCallback,
  }) {
    final List<String> arguments = [];
    if (composeFile != null) {
      arguments.addAll(["-f", composeFile.path]);
    }
    if (projectName != null) {
      arguments.addAll(["-p", projectName]);
    }
    arguments.add("stop");

    return Shell(
      program: "docker-compose",
      arguments: arguments,
      options: ProcessInterfaceOptions(
        runAsAdministrator: true,
        workingDirectory: workingDirectory,
      ),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Stops and/or removes containers, networks, images, and volumes.
  static Step shutdown({
    required File? composeFile,
    required String? projectName,
    bool removeVolumes = false,
    bool removeImages = false,
    DockerOutputCallback? onCallback,
  }) {
    final List<String> arguments = [];
    if (composeFile != null) {
      arguments.addAll(["-f", path.basename(composeFile.path)]);
    }
    arguments.add("down");
    if (removeVolumes) arguments.add("-v");
    if (removeImages) arguments.addAll(["--rmi", "all"]);

    return Shell(
      program: "docker-compose",
      arguments: arguments,
      options: ProcessInterfaceOptions(
        runAsAdministrator: true,
        workingDirectory: composeFile != null
            ? path.dirname(composeFile.path)
            : null,
      ),
      onStdout: (context, chars) => onCallback?.call(context, chars, false),
      onStderr: (context, chars) => onCallback?.call(context, chars, true),
    );
  }

  /// Checks if any containers defined in the compose file are currently running.
  static bool isRunning({
    File? composeFile,
    String? projectName,
    String? workingDirectory,
  }) {
    final List<String> arguments = [];
    if (composeFile != null) {
      arguments.addAll(["-f", composeFile.path]);
    }
    if (projectName != null) {
      arguments.addAll(["-p", projectName]);
    }
    arguments.addAll(["ps", "--quiet", "--filter", "status=running"]);

    try {
      final result = Process.runSync(
        "docker-compose",
        arguments,
        workingDirectory: workingDirectory,
      );
      return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
