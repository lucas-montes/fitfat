# Logging

## How to view logs from your phone

### Android (adb logcat)

1. Connect your phone via USB
2. Open a terminal and run:
```bash
adb logcat | grep -i fitfat
```

To see only our app's logs with timestamps:
```bash
adb logcat -v time | grep -i "fitfat\|Flutter"
```

Filter by log level:
```bash
adb logcat *:E                      # Only errors
adb logcat -v time | grep "fitfat"  # Only fitfat logs with time
```

### Flutter DevTools

```bash
flutter logs
```
This shows all Flutter/Dart logs in real-time while the app is running.

---

## Logging system

The app uses `package:logging/logging.dart` — a standard Dart logging library.

### Setup

Add to `pubspec.yaml`:
```yaml
dependencies:
  logging: ^1.2.0
```

Initialize in `main.dart`:
```dart
import 'package:logging/logging.dart';

void main() {
  // Configure logging level
  Logger.root.level = Level.ALL; // Show everything
  Logger.root.onRecord.listen((record) {
    // Output to console in a readable format
    print('[${record.level.name}] ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      print('  Error: ${record.error}');
      print('  Stack: ${record.stackTrace}');
    }
  });

  runApp(...);
}
```

### Usage

```dart
import 'package:logging/logging.dart';

final log = Logger('SeanceHistoryNotifier');

// Different levels:
log.fine('Loading history from DB...');
log.info('Seance completed: ${seance.id}');
log.warning('Found ${exercises.length} exercises with empty names');
log.severe('Failed to save seance', error, stackTrace);
```

### Log levels

| Level | When to use | Color / tag |
|---|---|---|
| `FINEST` | Trace-level debugging — every step of a loop | Gray |
| `FINE` | Detailed flow — "entering method X" | Gray |
| `CONFIG` | Configuration changes — "DB opened" | White |
| `INFO` | Important events — "seance completed" | Green |
| `WARNING` | Something unexpected but recoverable | Yellow |
| `SEVERE` | Errors that need fixing | Red |
| `SHOUT` | Catastrophic failures | Bold Red |

### What to log

- **All `catch` blocks** — `log.severe('message', error, stackTrace)`
- **User actions** — `log.info('User started blank seance')`
- **DB operations** — `log.fine('Saving seance ${seance.id} to DB')`
- **Navigation** — `log.info('Navigated to /current-seance')`

### What NOT to log

- Sensitive data
- Every single setState call
- Widget build methods (too verbose)

---

## Adding logs to fitfat

The current `debugPrint()` calls in `exercise_providers.dart` should be replaced with `logging`. Create a file `lib/src/services/logger.dart`:

```dart
import 'package:logging/logging.dart';

final log = Logger('fitfat');
```

Then use it in providers:

```dart
import '../services/logger.dart' as app;

// In catch blocks:
} catch (e, stack) {
  log.severe('Failed to save seance', e, stack);
}
```
