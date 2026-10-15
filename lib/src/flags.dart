import 'package:natrix/core.dart';

class IntFlag extends NatrixFlag<int> {
  const IntFlag({
    required super.id,
    required super.value,
    super.acronym,
    super.examples,
    super.tooltip,
  });

  @override
  String format(int value) => value.toString();

  @override
  int parse(String raw) => int.parse(raw);

  @override
  NatrixFlag<int> set(int value) => IntFlag(
    id: id,
    value: value,
    acronym: acronym,
    tooltip: tooltip,
    examples: examples,
  );
}

class DurationFlag extends NatrixFlag<Duration> {
  const DurationFlag({
    required super.id,
    super.acronym,
    super.examples,
    super.tooltip,
    required super.value,
  });

  @override
  String format(Duration value) {
    List<String> parts = [];
    if (value.inDays > 0) parts.add("${value.inDays}d");
    int hours = value.inHours % 24;
    if (hours > 0) parts.add("${hours}h");
    int minutes = value.inMinutes % 60;
    if (minutes > 0) parts.add("${minutes}m");
    int seconds = value.inSeconds % 60;
    if (seconds > 0) parts.add("${seconds}s");
    return parts.isEmpty ? "0s" : parts.join(":");
  }

  @override
  Duration parse(String raw) {
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

  @override
  NatrixFlag<Duration> set(Duration value) {
    return DurationFlag(
      id: id,
      tooltip: tooltip,
      acronym: acronym,
      examples: examples,
      value: value,
    );
  }
}
