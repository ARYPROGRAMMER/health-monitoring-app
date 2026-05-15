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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB7n-t-ge7zH7vsKsCtCQBRLCO-wzG2IDw',
    appId: '1:819719711174:web:ecc171e45dd0ffe0cdeac7',
    messagingSenderId: '819719711174',
    projectId: 'stealthera',
    authDomain: 'stealthera.firebaseapp.com',
    storageBucket: 'stealthera.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD19fhQE6RtRaxb3MGwi7dlEu13HFI0IO8',
    appId: '1:819719711174:android:9308530ac427d227cdeac7',
    messagingSenderId: '819719711174',
    projectId: 'stealthera',
    storageBucket: 'stealthera.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDgUMGtMbZ4GG9imt12zpuv6oSt3OtU3PE',
    appId: '1:819719711174:ios:c2eac9c3b3e89512cdeac7',
    messagingSenderId: '819719711174',
    projectId: 'stealthera',
    storageBucket: 'stealthera.firebasestorage.app',
    iosBundleId: 'com.example.healthMonitoringApp',
  );
}
