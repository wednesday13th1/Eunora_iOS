# Eunora_iOS

A gentle, native SwiftUI companion for a recovery voyage — built around private check-ins, small self-care quests, and calm, non-judgmental progress.

## Native account configuration

Set `EUNORA_API_BASE_URL` in the app target’s build settings to the verified HTTPS origin of the Eunora Express API. The build places it in `EunoraAPIBaseURL` in the app’s Info.plist. An unset value leaves guest mode available and disables account actions. The app needs no Supabase keys or admin credentials.

The native account screen uses the backend’s `/auth/signup`, `/auth/login`, `/auth/refresh`, and `/auth/logout` routes. It keeps session credentials in Keychain and does not upload guest data. The reviewed backend has no passkey or account deletion endpoint. Remote logout revokes the backend session only when the server has its service role key configured.

Run the shared `Eunora_ios` scheme’s Test action on an iOS 27+ iPhone simulator. The API contract tests use local URLSession fixtures. Use an isolated app bundle identifier for UI tests if Eunora is already installed on the simulator.

See [the native parity audit](NATIVE_PARITY.md) for source revisions and remaining gaps.
