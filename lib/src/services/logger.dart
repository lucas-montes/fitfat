import 'package:logging/logging.dart';

/// Initialize logging. Call once in main().
void initLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('[${record.level.name}] ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      // ignore: avoid_print
      print('  Error: ${record.error}');
      // ignore: avoid_print
      print('  Stack: ${record.stackTrace}');
    }
  });
}

/// Create a named logger for a class or module.
Logger logger(String name) => Logger(name);
