# Email Confirmation Deep Link Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire up a `scrollbooks://` custom URL scheme so tapping the Supabase confirmation email link opens the app and logs the user in automatically.

**Architecture:** Three independent changes: (1) add `app_links` package and register the URL scheme in Android and iOS platform config, (2) pass `emailRedirectTo: 'scrollbooks://auth-callback'` in the `signUp` call, (3) add an `AppLinks` listener in `main.dart` that calls `Supabase.instance.client.auth.getSessionFromUrl(uri)`. The existing `onAuthStateChange` listener in `main.dart` already handles everything after the session is established — no router or provider changes needed.

**Tech Stack:** Flutter, `app_links ^6.0.0`, `supabase_flutter ^2.3.0`

---

## Background: how the flow works

1. User taps the confirmation link in the email
2. Browser opens the Supabase verification URL (`https://[project].supabase.co/auth/v1/verify?...`)
3. Supabase validates the token and redirects to `scrollbooks://auth-callback#access_token=...&refresh_token=...`
4. Android/iOS intercepts the `scrollbooks://` scheme and opens the app
5. `AppLinks.uriLinkStream` (or `getInitialAppLink` on cold start) fires with the URL
6. `getSessionFromUrl(uri)` creates a session
7. The existing `onAuthStateChange` listener fires → `AppProvider.load()` runs → router redirects to `/app/library`

**Supabase Dashboard** (already done by the user):
- Site URL: `scrollbooks://auth-callback`
- Redirect URLs allowlist: `scrollbooks://auth-callback`

---

### Task 1: Add `app_links` dependency and register URL scheme on both platforms

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

> Note: Platform config and pubspec changes have no unit tests. Correctness is verified by running the test suite (nothing breaks) and the manual smoke test at the end.

---

**Step 1: Add `app_links` to `pubspec.yaml`**

In `pubspec.yaml`, under `dependencies:`, add after the existing entries:

```yaml
  app_links: ^6.0.0
```

**Step 2: Install the package**

```bash
cd /path/to/worktree
flutter pub get
```

Expected: resolves cleanly, no version conflicts.

**Step 3: Add Android intent-filter to `AndroidManifest.xml`**

In `android/app/src/main/AndroidManifest.xml`, the `<activity android:name=".MainActivity" ...>` block currently has one `<intent-filter>` (the MAIN/LAUNCHER one). Add a second one directly after it:

```xml
        <intent-filter>
            <action android:name="android.intent.action.VIEW"/>
            <category android:name="android.intent.category.DEFAULT"/>
            <category android:name="android.intent.category.BROWSABLE"/>
            <data android:scheme="scrollbooks" android:host="auth-callback"/>
        </intent-filter>
```

The full `<activity>` block should now look like:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:taskAffinity=""
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    <meta-data
      android:name="io.flutter.embedding.android.NormalTheme"
      android:resource="@style/NormalTheme"
      />
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="scrollbooks" android:host="auth-callback"/>
    </intent-filter>
</activity>
```

**Step 4: Add iOS URL scheme to `ios/Runner/Info.plist`**

In `ios/Runner/Info.plist`, add the `CFBundleURLTypes` key before the closing `</dict>` tag (just before `</dict></plist>`):

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>scrollbooks</string>
			</array>
		</dict>
	</array>
```

**Step 5: Run the test suite to confirm nothing broke**

```bash
flutter test
```

Expected: all tests pass (platform config changes don't affect unit tests).

**Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "feat: register scrollbooks:// URL scheme on Android and iOS"
```

---

### Task 2: Add `emailRedirectTo` to the `signUp` call

**Files:**
- Modify: `lib/screens/signup_screen.dart` (line 39–43)
- Test: `test/screens/signup_screen_test.dart` (run existing, no new tests needed)

> Note: `emailRedirectTo` is passed directly to the Supabase SDK. The project doesn't mock the Supabase client in tests, so the parameter value itself cannot be unit-tested. The existing tests verify the form still renders and validates correctly after the change.

---

**Step 1: Run the existing signup tests as baseline**

```bash
flutter test test/screens/signup_screen_test.dart
```

Expected: 6 tests pass.

**Step 2: Add `emailRedirectTo` to the `signUp` call**

In `lib/screens/signup_screen.dart`, find the `supabase.auth.signUp(...)` call (around line 39):

```dart
// BEFORE:
await supabase.auth.signUp(
  email: _email.text.trim(),
  password: _password.text,
  data: {'display_name': _name.text.trim()},
);

// AFTER:
await supabase.auth.signUp(
  email: _email.text.trim(),
  password: _password.text,
  data: {'display_name': _name.text.trim()},
  emailRedirectTo: 'scrollbooks://auth-callback',
);
```

**Step 3: Run the signup tests again**

```bash
flutter test test/screens/signup_screen_test.dart
```

Expected: all 6 tests still pass.

**Step 4: Run the full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add lib/screens/signup_screen.dart
git commit -m "feat: add emailRedirectTo to signUp for deep link confirmation"
```

---

### Task 3: Add deep link listener in `main.dart`

**Files:**
- Modify: `lib/main.dart`

> Note: `AppLinks.uriLinkStream` is a platform channel stream. It cannot be unit-tested without a full platform harness. Correctness is verified by the manual smoke test.

---

**Step 1: Add the import**

In `lib/main.dart`, add after the existing imports:

```dart
import 'package:app_links/app_links.dart';
```

**Step 2: Add `_handleDeepLinks()` method to `_AppWithAuthState`**

In `lib/main.dart`, add this method to the `_AppWithAuthState` class:

```dart
void _handleDeepLinks() {
  final appLinks = AppLinks();
  // Cold start: app was opened via the deep link
  appLinks.getInitialAppLink().then((uri) async {
    if (uri != null) {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    }
  });
  // Warm start: app was already running when the link arrived
  appLinks.uriLinkStream.listen((uri) async {
    await Supabase.instance.client.auth.getSessionFromUrl(uri);
  });
}
```

**Step 3: Call `_handleDeepLinks()` from `initState()`**

The current `initState()` in `_AppWithAuthState` is:

```dart
@override
void initState() {
  super.initState();
  Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    if (event.session != null) {
      context.read<AppProvider>().load(event.session!.user.id);
    }
  });
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().load(session.user.id);
    });
  }
}
```

Add `_handleDeepLinks();` at the end:

```dart
@override
void initState() {
  super.initState();
  Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    if (event.session != null) {
      context.read<AppProvider>().load(event.session!.user.id);
    }
  });
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().load(session.user.id);
    });
  }
  _handleDeepLinks();
}
```

**Step 4: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add lib/main.dart
git commit -m "feat: handle scrollbooks:// deep links for email confirmation"
```

---

## Manual Smoke Test

After all three tasks are merged and running on a physical device:

1. Run on device:
   ```bash
   flutter run --release -d <device-id>
   ```
2. Sign up with a **real email address** you can access
3. Check your inbox → tap the confirmation link in the email
4. The app should open immediately (no browser error)
5. You should land on `/app/library` (logged in, no manual login needed)

**Cold start test:**
1. Close the app completely
2. Tap the confirmation link in the email
3. The app should open and log you in directly
