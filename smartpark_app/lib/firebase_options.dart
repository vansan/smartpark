// Firebase configuration for SmartPark
// Generated from Firebase Console — Project: smartpark-60dc2

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return web; // Use web config for Windows desktop
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─── Web & Windows ────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCm3e4r21GJ_-pZZMPfTwyxyqEtRB4vWGA',
    appId: '1:852869663452:web:e8998b9ec92f1845dac219',
    messagingSenderId: '852869663452',
    projectId: 'smartpark-60dc2',
    authDomain: 'smartpark-60dc2.firebaseapp.com',
    storageBucket: 'smartpark-60dc2.firebasestorage.app',
  );

  // ─── Android ──────────────────────────────────────────────────────────────
  // TODO: Replace with values from google-services.json once downloaded
  // Get it from Firebase Console → Project Settings → Android app → Download
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCm3e4r21GJ_-pZZMPfTwyxyqEtRB4vWGA',
    appId: '1:852869663452:android:REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: '852869663452',
    projectId: 'smartpark-60dc2',
    storageBucket: 'smartpark-60dc2.firebasestorage.app',
  );

  // ─── iOS (not used in POC) ────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCm3e4r21GJ_-pZZMPfTwyxyqEtRB4vWGA',
    appId: '1:852869663452:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '852869663452',
    projectId: 'smartpark-60dc2',
    storageBucket: 'smartpark-60dc2.firebasestorage.app',
    iosBundleId: 'com.smartpark.app',
  );
}
