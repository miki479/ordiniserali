# Vico Meal

Flutter rewrite of the "Vico Meal" evening order app: sign in with a
name-derived account, order dinner, and — for team leads (capolinea) —
manage the day's orders, generate the restaurant PDF, and manage members.

## Stack

- **Material 3**, light/dark theme (follows the system setting)
- **Riverpod** for state management (`Notifier` / `AsyncNotifier`, no code
  generation)
- **GoRouter** for navigation, redirecting based on a single auth/identity
  state machine (`SessionController`)
- **Firebase** (Auth + Firestore) as the backend, same data model as the
  original web app (`ordini`, `utenti`, `giorni`, `capolinea_autorizzati`,
  `superuser_autorizzati`, `eliminazioni_log` collections)
- **flutter_localizations** + generated `AppLocalizations` (`lib/l10n`),
  Italian (source) and English shipped, more locales are a matter of adding
  another `.arb` file
- Clean-ish layering: `domain` (entities, repository interfaces, use cases)
  → `data` (Firestore/local implementations) → `presentation` (Riverpod
  providers + screens), see `lib/`

## Before you run it

1. **Firebase config**: `lib/firebase_options.dart` currently reuses the
   original app's *web* Firebase config for Android and iOS too, so
   Auth/Firestore work out of the box for development. Before publishing,
   run `flutterfire configure` (Firebase CLI, logged into the project
   owner's account) to register real Android/iOS apps — this also produces
   `android/app/google-services.json` and
   `ios/Runner/GoogleService-Info.plist` and registers the Android SHA-1
   fingerprint.
2. `flutter pub get` (also regenerates `lib/l10n/app_localizations*.dart`,
   which are gitignored build outputs).
3. `flutter run`.

## Tests

`flutter test` covers the pure-logic utilities (name normalization,
slugification, order-text sanitization) in `test/`. UI/integration coverage
would need a Firebase emulator to fake Auth/Firestore and hasn't been added
yet.
