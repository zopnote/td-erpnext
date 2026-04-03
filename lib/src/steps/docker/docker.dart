import 'dart:async';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart' hide Command;

import 'package:td_erpnext/src/steps/docker/steps/copy.dart';
import 'package:td_erpnext/src/steps/docker/steps/execute.dart';
import 'package:td_erpnext/src/steps/docker/steps/images.dart';
import 'package:td_erpnext/src/steps/docker/steps/list.dart';
import 'package:td_erpnext/src/steps/docker/steps/remove.dart';
import 'package:td_erpnext/src/steps/docker/steps/run.dart';
import 'package:td_erpnext/src/steps/docker/steps/start.dart';
import 'package:td_erpnext/src/steps/docker/steps/stop.dart';
import 'package:td_erpnext/src/steps/docker/steps/update.dart';

export 'package:td_erpnext/src/steps/docker/steps/copy.dart';
export 'package:td_erpnext/src/steps/docker/steps/execute.dart';
export 'package:td_erpnext/src/steps/docker/steps/images.dart';
export 'package:td_erpnext/src/steps/docker/steps/list.dart';
export 'package:td_erpnext/src/steps/docker/steps/remove.dart';
export 'package:td_erpnext/src/steps/docker/steps/run.dart';
export 'package:td_erpnext/src/steps/docker/steps/start.dart';
export 'package:td_erpnext/src/steps/docker/steps/stop.dart';
export 'package:td_erpnext/src/steps/docker/steps/update.dart';

export 'container.dart';
export 'image.dart';
export 'location.dart';
export 'config.dart';
export 'volume.dart';

/// Callback signature for process output.
typedef DockerOutputCallback =
    FutureOr<void> Function(FlowContext context, List<int> chars, bool isError);

abstract class DockerStep<
  Wiser extends StepWiser<Docker, Wiser, SingleStep<Docker, Wiser>>
>
    extends SingleStep<Docker, Wiser> {
  @override
  Step configure() => Shell(
    program: step.programCallLiteral,
    arguments: format(),
    options: const ProcessInterfaceOptions(runAsAdministrator: true),
    onStdout: (context, chars) => step.onCallback?.call(context, chars, false),
    onStderr: (context, chars) => step.onCallback?.call(context, chars, true),
  );
  List<String> format();
}

extension ArgumentBuildListExtension on List<String> {
  void addIf(bool condition, String value) {
    if (condition) add(value);
  }

  void addAllIf(bool condition, Iterable<List<String>> value) {
    if (!condition) return;
    for (final v in value) {
      addAll(v);
    }
  }

  void addNotNull<T>(T? value, String Function(T) map) {
    if (value != null) add(map(value));
  }

  void addAllNotNull<T>(T? value, List<String> Function(T) map) {
    if (value != null) addAll(map(value));
  }
}

/// Main entry point for Docker commands.
final class Docker extends CollectionStep<Docker> {
  const Docker({this.onCallback, this.programCallLiteral = "docker"});
  final DockerOutputCallback? onCallback;
  final String programCallLiteral;

  /// Executes a command in a running container.
  Step exec(ExecSettings settings) => stepwise<Exec, ExecSettings>(settings);

  /// Copies files/folders between a container and the local filesystem.
  Step copy(CopySettings settings) => stepwise<Copy, CopySettings>(settings);

  /// Starts one or more stopped containers.
  Step start(StartSettings settings) =>
      stepwise<Start, StartSettings>(settings);

  /// Stops one or more running containers.
  Step stop(StopSettings settings) => stepwise<Stop, StopSettings>(settings);

  /// Removes one or more containers.
  Step remove(RemoveSettings settings) =>
      stepwise<Remove, RemoveSettings>(settings);

  /// Lists containers.
  Step list(ListsSettings settings) => stepwise<Lists, ListsSettings>(settings);

  /// Lists images.
  Step images(ImagesSettings settings) =>
      stepwise<Images, ImagesSettings>(settings);

  /// Updates configuration of one or more containers.
  Step update(UpdateSettings settings) =>
      stepwise<Update, UpdateSettings>(settings);

  /// Runs a command in a new container.
  Step run(RunSettings settings) => stepwise<Run, RunSettings>(settings);
}
