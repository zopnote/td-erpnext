import 'dart:io' as io;
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:stepflow/io.dart';
import 'package:stepflow/core.dart';
import 'package:stepflow/platform.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:yaml/yaml.dart';

import 'get_project_root.dart';

Future<io.Directory> get projectRoot async => await getProjectRoot();

class PackageSpecification {
  final String name;
  final String description;
  final String version;
  final String entrypointFileName;

  const PackageSpecification({
    required this.name,
    required this.description,
    required this.version,
    required this.entrypointFileName,
  });
}

class BuildWorkflow extends ConfigureStep {
  final io.Directory projectRoot;
  final String outDirectoryName;
  final void Function(io.File executable)? buildFinishCallback;
  final io.File readme;
  final io.File pubspec;

  const BuildWorkflow({
    required this.projectRoot,
    required this.outDirectoryName,
    required this.readme,
    required this.pubspec,
    this.buildFinishCallback,
  });

  static PackageSpecification _loadPackageInfo(io.File pubspec) {
    final Uint8List bytes = pubspec.readAsBytesSync();
    final document = loadYaml(String.fromCharCodes(bytes));
    return PackageSpecification(
      name: document["executable"],
      description: document["description"],
      version: document["version"],
      entrypointFileName: document["entrypoint"],
    );
  }

  @override
  Step configure() {
    final PackageSpecification pubspec = _loadPackageInfo(this.pubspec);
    final io.Directory output = io.Directory(
      path.join(
        projectRoot.path,
        outDirectoryName,
        Platform.current().name(),
        pubspec.name,
      ),
    );
    bool isOpen = true;
    return Chain(
      steps: [
        Runnable((context) {
          if (!io.Platform.isLinux) {
            context.pop("The application is only available on linux.");
          }
        }),
        Check(
          programs: ["dart", "git"],
          onFailure: (context, programs) => context.pop(
            "The following dependencies aren't satisfied: ${programs.join(", ")}.",
          ),
        ),
        CreateDirectory(path.join(output.path, "bin"), recursive: true),
        Runnable((_) => print("Building project...")),
        Shell(
          program: "dart",
          arguments: [
            "compile",
            "exe",
            path.join(projectRoot.path, "bin", pubspec.entrypointFileName),
            "--output=${path.join(output.path, "bin", pubspec.name)}$executableExtension",
          ],
          options: ProcessInterfaceOptions(workingDirectory: projectRoot.path),
          onStderr: (context, chars) {
            io.stderr.add(chars);
            if (isOpen) {
              context.pop(
                "An error occurred while the compilation of the project.",
              );
              isOpen = false;
            }
          },
        ),
        Runnable(
          (context) => buildFinishCallback != null
              ? buildFinishCallback!(
                  io.File(
                    "${path.join(output.path, "bin", pubspec.name)}$executableExtension",
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

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
  Step configure() => Runnable((context) async {
    final bool exists = await io.Directory(path).exists();
    if (exists) {
      if (!deleteIfExists) {
        return;
      }
      await io.Directory(path).delete(recursive: true);
    }
    await io.Directory(path).create(recursive: recursive);
  });
}

extension PlatformString on Platform {
  String name() =>
      "${attributes.name == os.name ? os.name : "${os.name}-${attributes.name}"}-${attributes.arch.name}";
}
