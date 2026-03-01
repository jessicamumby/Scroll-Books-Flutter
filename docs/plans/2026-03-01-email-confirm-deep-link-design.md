# Email Confirmation Deep Link — Design

## Problem

The Supabase confirmation email contains a link pointing to `localhost:3000` (the default Site URL). Tapping it on a phone produces "localhost not found". There is no URL scheme registered in the app to intercept the redirect.

## Solution

Register a custom URL scheme (`scrollbooks://`) on both platforms. Pass `emailRedirectTo: 'scrollbooks://auth-callback'` in the `signUp` call. When the user taps the confirmation link, the browser validates the token with Supabase, which then redirects to `scrollbooks://auth-callback#access_token=...`. The app intercepts that URL via `app_links`, calls `supabase.auth.getSessionFromUrl(uri)`, and the existing `onAuthStateChange` listener in `main.dart` takes over — `AppProvider.load()` runs and the router redirects to `/app/library`.

## Supabase Dashboard (already done)

- **Site URL**: `scrollbooks://auth-callback`
- **Redirect URLs allowlist**: `scrollbooks://auth-callback`

## Design

### Part 1 — Android (`android/app/src/main/AndroidManifest.xml`)

Add a second `<intent-filter>` inside the `<activity>` block for `MainActivity`:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="scrollbooks" android:host="auth-callback"/>
</intent-filter>
```

### Part 2 — iOS (`ios/Runner/Info.plist`)

Add a `CFBundleURLTypes` array entry:

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

### Part 3 — `pubspec.yaml`

Add dependency:

```yaml
app_links: ^6.0.0
```

### Part 4 — `lib/screens/signup_screen.dart`

Add `emailRedirectTo` to the `supabase.auth.signUp` call:

```dart
await supabase.auth.signUp(
  email: _email.text.trim(),
  password: _password.text,
  data: {'display_name': _name.text.trim()},
  emailRedirectTo: 'scrollbooks://auth-callback',
);
```

### Part 5 — `lib/main.dart`

In `_AppWithAuthState.initState()`, add an `AppLinks` deep link listener after the existing `onAuthStateChange` listener:

```dart
final appLinks = AppLinks();
appLinks.uriLinkStream.listen((uri) async {
  await supabase.auth.getSessionFromUrl(uri);
});
```

Import: `import 'package:app_links/app_links.dart';`

The existing `onAuthStateChange` listener already calls `AppProvider.load()` and the router redirects to `/app/library` — no further changes needed.

## Files

- `android/app/src/main/AndroidManifest.xml` — add intent-filter
- `ios/Runner/Info.plist` — add CFBundleURLSchemes
- `pubspec.yaml` — add app_links dependency
- `lib/main.dart` — add AppLinks deep link listener
- `lib/screens/signup_screen.dart` — add emailRedirectTo to signUp call
- `test/screens/signup_screen_test.dart` — verify emailRedirectTo is passed

## Out of Scope

- Changing the confirmation email template
- Handling password reset deep links (separate concern)
- Universal Links / App Links (HTTPS scheme)
