# Seance foreground & notification setup (developer notes)

Required changes / steps when implementing T01 (Current Seance background timer)

Android
- Add the `FOREGROUND_SERVICE` permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

- If using a native foreground service, declare it in the manifest under the `<application>` element.
- Ensure the notification channel (id `seance_channel`) is created before starting a foreground service.
- Note: Play Store policies require explaining long-running background work in your app description if applicable.

iOS
- Request notification permission using `UNUserNotificationCenter` / `flutter_local_notifications` at app startup or when the user starts a seance.
- iOS does not allow arbitrary continuous background Dart execution; the app should show a best-effort local notification and provide in-app indicator for accurate timing.

Testing
- Android: test on emulator and at least one physical device (Pixel, Samsung). Verify notification persists while app is backgrounded and lock-screen shows notification.
- iOS: verify local notification appears and tapping it opens the app to the Current Seance screen.

Developer note
- This is an initial scaffold implementation using `flutter_local_notifications`. For a robust Android foreground service consider `flutter_foreground_task` or a native service bridge.
