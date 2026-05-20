// File: lib/firebase_options.dart
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDD0UQ13v5SnU_cPCX3VjcxjUebpLwexlE',
    appId: '1:276271513380:web:b95372e50c50924007fdb1',
    messagingSenderId: '276271513380',
    projectId: 'mobile-app-project-expense',
    authDomain: 'mobile-app-project-expense.firebaseapp.com',
    storageBucket: 'mobile-app-project-expense.firebasestorage.app',
    measurementId: 'G-B0X2VE53LB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDD0UQ13v5SnU_cPCX3VjcxjUebpLwexlE',
    appId: '1:276271513380:android:3f1aa2fca9b6a124007fdb1',
    messagingSenderId: '276271513380',
    projectId: 'mobile-app-project-expense',
    storageBucket: 'mobile-app-project-expense.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDD0UQ13v5SnU_cPCX3VjcxjUebpLwexlE',
    appId: '1:276271513380:ios:4b1aa2fca9b6a124007fdb1',
    messagingSenderId: '276271513380',
    projectId: 'mobile-app-project-expense',
    storageBucket: 'mobile-app-project-expense.firebasestorage.app',
    iosBundleId: 'com.example.smartExpenseTracker',
  );
}
