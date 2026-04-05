import 'dart:io';

/// Checks if any containers defined in the compose file are currently running.
bool isRunning({
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
