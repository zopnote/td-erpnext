import 'package:stepflow/io.dart';

class IntFlag extends Flag<int> {
  IntFlag({
    required super.name,
    required super.value,
    super.description,
    super.examples,
  }) : super(parse: _parse, format: _format);
  static String _format(int value) => value.toString();
  static int _parse(String raw) => int.parse(raw);
}

class DurationFlag extends Flag<Duration> {
  DurationFlag({
    required super.name,
    required super.value,
    super.description,
    super.examples,
  }) : super(parse: _parse, format: _format);
  static String _format(Duration duration) {
    List<String> parts = [];
    if (duration.inDays > 0) parts.add("${duration.inDays}d");
    int hours = duration.inHours % 24;
    if (hours > 0) parts.add("${hours}h");
    int minutes = duration.inMinutes % 60;
    if (minutes > 0) parts.add("${minutes}m");
    int seconds = duration.inSeconds % 60;
    if (seconds > 0) parts.add("${seconds}s");
    return parts.isEmpty ? "0s" : parts.join(":");
  }

  static Duration _parse(String raw) {
    final regex = RegExp(r"(\d+)([dhms])");
    final matches = regex.allMatches(raw.toLowerCase());
    int days = 0, hours = 0, minutes = 0, seconds = 0;

    for (final match in matches) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2);
      switch (unit) {
        case 'd':
          days = value;
          break;
        case 'h':
          hours = value;
          break;
        case 'm':
          minutes = value;
          break;
        case 's':
          seconds = value;
          break;
      }
    }
    if (matches.isEmpty) {
      throw FormatException("Invalid duration format: $raw");
    }
    return Duration(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }
}
