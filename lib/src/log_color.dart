class LogColor {
  const LogColor._internal();
  static const String reset = '\x1B[0m';
  static String green(String msg) => "\x1B[32m$msg$reset";
  static String red(String msg) => "\x1B[31m$msg$reset";
  static String cyan(String msg) => "\x1B[36m$msg$reset";
  static String yellow(String msg) => "\x1B[33m$msg$reset";
}
