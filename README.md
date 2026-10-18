# iSkedyul — Phase 2

**Klase, gawain, at notes—ayos sa isang lugar.**

A Flutter Web student planner for a second-year student's solo mobile application project. Phase 2 adds browser-local persistence to the approved Phase 1 UI. There is no backend, login, external API, or paid service.

## What you can try

- First visit: Welcome → Get Started. Returning visits open Today.
- **Today**: class times, daily counts, and urgent tasks.
- **Week**: the weekly schedule grouped Monday–Sunday.
- **Tasks**: all pending tasks, followed by a separate completed section.
- Open a schedule to see its times, linked tasks, and one editable plain-text notes field.
- Create, edit, and delete schedules and tasks, with validation, save confirmations, and destructive-delete confirmation. Deleting a schedule also removes its linked tasks and notes. Cancel leaves everything unchanged.
- Select a weekday and times; the end must be after the start on the same day.
- Link every task to exactly one schedule, choose a due date and High/Medium/Low priority, and toggle completion.
- Pending overdue tasks appear first, then priority, then nearest due date; completed tasks appear in a separate section on the dashboard and schedule details. All pending tasks remain accessible in the Tasks tab. “Urgent” includes overdue, due today, and High-priority pending tasks.

On a browser's first visit, sample data is added once with dates relative to the current browser date. After that, your saved data is restored; deleting everything intentionally leaves an empty planner after refresh. Weekly entries are stored as weekdays, not individual dated events. The UI uses grayscale, text status labels, built-in icons and bundled DejaVu fonts (license in `assets/fonts/LICENSE.txt`). Layouts scroll in portrait, landscape and desktop sizes.

## Project approach

The course rubric guides the concept, responsive screens, navigation, validation and local saving. The current target is Flutter Web, usable in a phone or laptop browser. Development, testing, and compilation happen in the cloud. GitHub hosts the live app and distributes ready-to-run downloads; the user's laptop does not need Flutter, Android Studio, an emulator, or Go.

## Use the app without Flutter

Once deployed, open **https://EzekielPalma.github.io/iskedyul/** in a modern browser. Deployment requires the GitHub setup below; adding this workflow does not by itself publish the site.

### GitHub Pages setup (repository owner)

1. Push this source code to the `main` branch of `EzekielPalma/iskedyul`.
2. In GitHub **Settings → Pages → Build and deployment → Source**, choose **GitHub Actions**.
3. In **Actions**, enable workflows if GitHub asks. Check that the **Flutter Web** workflow finishes successfully. If the `github-pages` environment requires approval, approve its deployment.
4. Open the deployment URL from the completed action or Settings → Pages.

The workflow pins **Flutter stable 3.47.7**, matching `.flutter-version` and the cloud SDK. It formats-checks, analyzes, tests, and produces two distinct builds. Pull requests run verification and upload the local artifact but do not deploy. Pushes to `main` also deploy Pages, using the required **`/iskedyul/` base path**. If the repository is renamed or uses a custom domain, adjust that base path. Pages deployment uses GitHub's `GITHUB_TOKEN` permissions; no personal token is needed.

### Download and run on another laptop

1. Open **[the latest GitHub release](https://github.com/EzekielPalma/iskedyul/releases/latest)**.
2. Under **Assets**, download the ZIP for your laptop:

   | Laptop | Download |
   | --- | --- |
   | Windows (64-bit Intel/AMD) | `iskedyul-windows-x64.zip` |
   | Linux (64-bit Intel/AMD) | `iskedyul-linux-x64.zip` |
   | Mac with Apple silicon (M1 or newer) | `iskedyul-macos-apple-silicon.zip` |
   | Mac with Intel processor | `iskedyul-macos-intel.zip` |

3. Extract the **entire ZIP** to a folder. Keep `Start-iSkedyul` and the `web` folder together.
4. Open **`Start-iSkedyul.exe`** on Windows, or **`Start-iSkedyul`** on Linux/macOS. It opens the app in your default browser.
5. Keep the launcher window open while using the app. Close it or press Ctrl+C when finished.

If the browser does not open automatically, visit **http://127.0.0.1:8080**. On Linux/macOS, you can open a terminal in the extracted folder and run `./Start-iSkedyul`. Your operating system may ask you to approve the unsigned launcher; only approve downloads you trust. On macOS, use the system's Open/Privacy & Security controls if it blocks the downloaded executable.

**No Flutter, emulator, Python, Node, or Go installation is needed on the laptop.** The small launcher serves the bundled app locally and only listens on this laptop. It is a compiled web app running in a browser, not an Android APK. Save the folder and reuse the same browser/address to keep the same planner. A different laptop starts its own local planner; this does not transfer your saved data.

The release also includes `iskedyul-web-server.zip` for people who already have a static HTTP server. Do not choose GitHub's auto-generated **Source code** ZIPs to run the app.

If a release has not appeared yet, check the **Flutter Web** workflow's **release** job. The same ready-to-run ZIPs are also under the `iskedyul-laptop-downloads` Actions artifact. Each successful push to `main` builds and publishes the download packages automatically.

### Optional: bare web build for an existing server

1. Open **Actions → Flutter Web → a successful run** while signed in to GitHub.
2. Under **Artifacts**, download **`iskedyul-web-local`** before GitHub's artifact retention period expires.
3. Extract the ZIP. The folder containing `index.html` is the web root. It also contains JavaScript, CanvasKit/WASM runtime files, icons, and bundled fonts/assets. Keep them together.
4. Serve that folder with a local static HTTP server. Do not double-click `index.html` (`file://` is unsupported).

This bare build needs an existing static HTTP server. Use the launcher download above to avoid installing one. For example, if Python 3 is already available, open a terminal in the extracted folder and run:

```sh
python3 -m http.server 8080 --bind 127.0.0.1
# On Windows, use: py -m http.server 8080 --bind 127.0.0.1
```

Then open `http://localhost:8080` in your browser. Stop the server with Ctrl+C. An existing editor's static HTTP server also works if it serves this folder at `/`. A static server is required; Python is just one option.

**GitHub “Code → Download ZIP” downloads source, not the ready-to-run app.** Use the release ZIP for your laptop, or the `iskedyul-web-local` Actions artifact for the bare compiled web files. The Pages artifact is a separate build for `/iskedyul/`; it is not the root-serving download.

All builds use `--no-web-resources-cdn` so the Flutter web runtime is bundled. Fonts and icons are also local; no Google Fonts requests are needed. This is not an offline-installable/PWA guarantee.

## Cloud development

Use the existing checkout; no local Flutter or Android SDK is required. The prepared cloud SDK is activated in each shell with:

```sh
source /workspace/.tooling/flutter-env.sh
cd /workspace/iskedyul
flutter --version
flutter pub get --enforce-lockfile
dart format lib test
flutter analyze
flutter test
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

The activation file is cloud-environment configuration, not a repository file. For another cloud machine or CI, install Flutter **3.47.7 stable**, add its `bin` directory to PATH, and enable web with `flutter config --enable-web`. Allow GitHub, `storage.googleapis.com` and `pub.dev` for SDK and package downloads. Android doctor warnings do not block the Web target.

Build commands (each replaces `build/web`):

```sh
# Root-serving downloadable build
flutter build web --release --base-href / --no-web-resources-cdn
# GitHub project Pages build
flutter build web --release --base-href /iskedyul/ --no-web-resources-cdn
```

### Build the local launchers in the cloud

Only the cloud build machine needs Go **1.27.2**. The launcher uses Go's standard library and adds no Flutter dependencies:

```sh
# After the root-serving Flutter build (not the /iskedyul/ build):
go test -C tool/launcher ./...
python3 tool/package_web.py
```

Packages are written to `build/downloads/`. CI cross-compiles Windows/Linux x64 and macOS Intel/Apple silicon launchers, uploads them, and publishes a GitHub release. Linux serving and browser behavior are tested in the cloud; Windows/macOS executables are cross-compiled and should be tried on their target laptops. Normal users download these compiled packages, not this toolchain.

## Small project structure

- `lib/main.dart`: theme and app entry point.
- `lib/data/models.dart`: schedules, tasks, and ordering helpers.
- `lib/data/demo_data.dart`: sample data, separate from screen code.
- `lib/data/app_state.dart`: state and save/delete operations using Flutter's ChangeNotifier and InheritedNotifier.
- `lib/data/snapshot.dart`: versioned JSON serialization, validation, and recovery.
- `lib/data/storage*.dart`: a small synchronous storage interface, native browser localStorage adapter, and in-memory test implementation.
- `lib/screens/screens.dart`: the six screens and their small shared widgets.
- `test/app_test.dart`: ordering, navigation, forms, delete confirmations, separate completed sections, and responsive layouts.
- `tool/launcher/` and `tool/package_web.py`: compiled local server and download packaging (cloud build tools only).
- `test/persistence_test.dart`: reload simulation, saved edits/completion/notes, cascading deletion, intentionally empty data, malformed saved data, and storage failure/retry.

There are no third-party runtime dependencies. Forms keep their own draft values; Cancel discards them. Each successful mutation saves schedules, tasks, completion status, priorities, dates, and notes together as one versioned JSON snapshot under localStorage key `iskedyul.data.v1`.

## Local saving and recovery

- Data survives refresh and browser restarts when browser storage is available. Use the same browser profile and site origin (scheme, hostname, and port). GitHub Pages and a downloaded local build have separate storage; changing local server ports also changes the saved planner.
- A missing storage key seeds the sample data once. A valid empty snapshot stays empty: samples are not reinserted after you delete all schedules.
- Invalid JSON or an unsupported snapshot starts an empty planner with a visible recovery notice. Valid snapshots containing invalid entries keep valid schedules/tasks and skip malformed rows, duplicate IDs, invalid dates/times, and tasks with missing schedules. Recovery does not overwrite the original snapshot until you make another change.
- If browser storage is blocked or full, the app remains usable in memory and displays a warning. It does not claim the change was saved; keep the tab open, resolve storage access/space, and make another change to retry saving. Reloading before a successful save loses unsaved changes.
- Notes are one plain-text field per schedule, limited to 2,000 characters. Titles and subjects are required; schedules must end after they start on the same day. Tasks require one existing linked schedule. Past due dates are allowed and become overdue when pending.
- Pending overdue tasks sort first, then High/Medium/Low priority, then nearest due date. Due dates use local calendar dates, with no time-of-day deadline. Completed tasks stay separate and can be unchecked or edited.
- Local storage is not backup or cloud sync. Clearing site data, switching profiles/devices, or private-session cleanup can remove access to saved data. Multiple simultaneous tabs are not synchronized; the last saved snapshot wins.

### Verification

Run the format, analyze, and test commands above. State tests reconstruct the app from the same storage to check saved edits, notes, completion toggles, linked deletion, empty data, and recovery. Widget tests exercise validation and confirmation/cancellation.

For a real-browser check, create and edit a schedule, add a linked task, edit its due date/priority, write notes, and toggle completion. Refresh and reopen the schedule: all changes should remain. Cancel a deletion, then confirm it and refresh: its tasks and notes should be gone while other classes remain. Delete all schedules and refresh again: the planner should stay empty. To test recovery on a throwaway local origin, replace `iskedyul.data.v1` with invalid JSON in browser developer tools and refresh; the app should show its recovery notice without crashing.

## Scope

Phase 2 implements browser-local saving/restoration and confirmed cascading deletion using the existing design. Notifications, cloud sync, accounts, attachments, rich text, calendar integration, generated timetables and conflict detection remain out of scope. GitHub deployment is complete only after the workflow runs successfully; local validation does not publish the site.
