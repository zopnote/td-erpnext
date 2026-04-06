import 'dart:io';

/// Checks if any containers defined in the compose file are currently running.
bool isRunning({
  required File composeFile,
  String? projectName,
  String? workingDirectory,
}) {
  final baseArgs = ["-f", composeFile.path];
  if (projectName != null) {
    baseArgs.addAll(["-p", projectName]);
  }

  try {
    // Container IDs holen
    final psResult = Process.runSync("docker-compose", [
      ...baseArgs,
      "ps",
      "--quiet",
    ], workingDirectory: workingDirectory);

    final ids = psResult.stdout
        .toString()
        .trim()
        .split('\n')
        .where((e) => e.isNotEmpty);

    if (ids.isEmpty) return false;

    // Prüfen ob mindestens einer läuft
    for (final id in ids) {
      final inspect = Process.runSync("docker", [
        "inspect",
        "-f",
        "{{.State.Running}}",
        id,
      ]);

      if (inspect.stdout.toString().trim() == "true") {
        return true;
      }
    }

    return false;
  } catch (_) {
    return false;
  }
}
