import 'dart:io';

import 'package:natrix/io.dart';

import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';

class CreateDirectory extends ConfigureStep {
  final String path;
  final bool recursive;
  final bool deleteIfExists;
  const CreateDirectory(
    this.path, {
    this.recursive = false,
    this.deleteIfExists = false,
  });
  @override
  Step configure() => Runnable(() async {
    final bool exists = await Directory(path).exists();
    if (exists) {
      if (!deleteIfExists) {
        return;
      }
      await Directory(path).delete(recursive: true);
    }
    await Directory(path).create(recursive: recursive);
  });
}

class PrintNatrixLine extends ConfigureStep {
  final NatrixText? text;
  const PrintNatrixLine({this.text});
  @override
  Step configure() =>
      Runnable(() => NatrixStdio().pipe(text: text ?? NatrixText.empty()));
}

class RenewNatrixLine extends ConfigureStep {
  final NatrixText? text;
  final NatrixMount mount;
  const RenewNatrixLine({required this.mount, this.text});
  @override
  Step configure() => Runnable(
    () => NatrixStdio().setLine(mount: mount, text: text ?? NatrixText.empty()),
  );
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
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

class InstallationNotFoundException implements Exception {
  @override
  String toString() =>
      "Couldn't find an installation at \"${Settings.repositoryPath}\".";
}

class AlreadyInstalledException implements Exception {
  @override
  String toString() =>
      "There is already an installation at \"${Settings.repositoryPath}\".";
}

class AlreadyRunningException implements Exception {
  const AlreadyRunningException();

  @override
  String toString() =>
      "The containers associated with the compose file are "
      "already running.";
}

class NotRunningException implements Exception {
  const NotRunningException();

  @override
  String toString() =>
      "The containers associated with the compose file aren't running.";
}

class UnavailableDependenciesException implements Exception {
  const UnavailableDependenciesException(this.dependencies);
  final List<String> dependencies;

  @override
  String toString() =>
      "The following dependencies aren't satisfied: ${dependencies.join(", ")}. ";

  @override
  bool operator ==(Object other) {
    if (other is! UnavailableDependenciesException) {
      return false;
    }
    return other.dependencies == dependencies;
  }
}
