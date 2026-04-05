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
      Runnable(() => NatrixStdio().newLine(text: text ?? NatrixText.empty()));
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
