import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase configuration for each platform.
///
/// The web values below are the existing "ordiniserali" Firebase project's
/// web app config (carried over from the original app). Android and iOS
/// don't have platform-specific apps registered in that Firebase project
/// yet — reusing the web config lets Auth/Firestore work immediately, but
/// **before publishing**, run `flutterfire configure` (with the Firebase
/// CLI logged into the project owner's account) to register real Android
/// and iOS apps and replace the two options below. That step also adds
/// `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`,
/// and registers the Android app's SHA-1/256 fingerprints.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyAExuqHi74XLGzGalZAlZTPMNtIPJ8zjyQ',
    authDomain: 'ordiniserali.firebaseapp.com',
    projectId: 'ordiniserali',
    storageBucket: 'ordiniserali.appspot.com',
    messagingSenderId: '60228923319',
    appId: '1:60228923319:web:98ded014014aee07b78232',
    measurementId: 'G-5KKLKNGTM5',
  );

  // TODO(flutterfire): replace with the real Android app config from
  // `flutterfire configure` before release.
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyAExuqHi74XLGzGalZAlZTPMNtIPJ8zjyQ',
    projectId: 'ordiniserali',
    storageBucket: 'ordiniserali.appspot.com',
    messagingSenderId: '60228923319',
    appId: '1:60228923319:web:98ded014014aee07b78232',
  );

  // TODO(flutterfire): replace with the real iOS app config from
  // `flutterfire configure` before release.
  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyAExuqHi74XLGzGalZAlZTPMNtIPJ8zjyQ',
    projectId: 'ordiniserali',
    storageBucket: 'ordiniserali.appspot.com',
    messagingSenderId: '60228923319',
    appId: '1:60228923319:web:98ded014014aee07b78232',
    iosBundleId: 'com.vicomeal.vicoMeal',
  );
}
