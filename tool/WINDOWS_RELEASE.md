Choose a compiled download below. Both versions include the dashboard, Day/Week/Month calendar, linked tasks, and notes.

### Android

Download **iskedyul-android.apk**, open it on your Android phone, and allow installation from that browser or file manager if Android asks. It installs as **iSkedyul** and runs directly as a Flutter Android app, without a browser, Flutter SDK, Android Studio, or emulator. Android 7.0 or later is required.

The APK was compiled and its signature checked; it has **not been tested on a phone or emulator**. It is development-signed for classroom sideloading, not Play Store publishing. A later build may have a different signing key and require uninstalling this build first; uninstalling erases its saved planner. Do not uninstall if you need to keep that data.

Schedules, tasks, completion and notes are saved privately on that device. They do not sync with the website or Windows version. App assets are bundled and the app needs no network access after installation. `iskedyul-android.apk.sha256` provides the download checksum.

### Windows

Download **iskedyul-windows-x64.zip**.

1. Extract the **entire ZIP** to a folder on a 64-bit Windows laptop.
2. Open **Start-iSkedyul.exe**. iSkedyul opens in your default browser.
3. Keep the launcher window open while using the app. Close it when finished.

No Flutter, Android Studio, emulator, Python, Node, or Go installation is needed. The app files, runtime, fonts, and icons are bundled, so internet is not required after downloading. This is the Flutter Web app with a Windows launcher.

Your planner is saved in that browser on that laptop. Use the same browser and address each time. Saved data does not transfer from GitHub Pages or another laptop.

If the browser does not open automatically, enter `http://127.0.0.1:8080`. If port 8080 is already in use, close the other launcher/server and try again. Windows may show a warning because the launcher is unsigned.

Choose the **iskedyul-windows-x64.zip** asset, rather than GitHub's automatically generated **Source code** downloads. `BUILD-INFO.txt` identifies the source commit in this package.
