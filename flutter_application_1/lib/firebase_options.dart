
















import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions chưa được cấu hình cho platform này. '
          'Hãy chạy: flutterfire configure',
        );
    }
  }



  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDbL_cGySXFJFmvPxmVqxqayUX83mImlOw",
    authDomain: "nihongotokyo-e9af2.firebaseapp.com",
    projectId: "nihongotokyo-e9af2",
    storageBucket: "nihongotokyo-e9af2.firebasestorage.app",
    messagingSenderId: "56132876251",
    appId: "1:56132876251:web:c889e00e0181ba07d799fe",
    measurementId: "G-YYL8G02K9K",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBRkohN5wYMmSBzB2hRCLI-8yl-JCfWTD8",
    appId: "1:56132876251:android:be802cfcd955435cd799fe",
    messagingSenderId: "56132876251",
    projectId: "nihongotokyo-e9af2",
    storageBucket: "nihongotokyo-e9af2.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDN_krayxCgsvzoPYJ4Vlz-ucg62sewGBw',
    appId: '1:1030822382399:ios:fa5683e270d7b10684618a',
    messagingSenderId: '1030822382399',
    projectId: 'nihongo-shadowing-98ab5',
    storageBucket: 'nihongo-shadowing-98ab5.firebasestorage.app',
    iosClientId:
        '1030822382399-nuubvh6l0js0utn7f6pghl06okv4ucml.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "AIzaSyDbL_cGySXFJFmvPxmVqxqayUX83mImlOw",
    authDomain: "nihongotokyo-e9af2.firebaseapp.com",
    projectId: "nihongotokyo-e9af2",
    storageBucket: "nihongotokyo-e9af2.firebasestorage.app",
    messagingSenderId: "56132876251",
    appId: "1:56132876251:web:c889e00e0181ba07d799fe",
    measurementId: "G-YYL8G02K9K",
  );
}