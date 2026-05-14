import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyCOyuasi0pp1A1779wzCyQfRHy3QOAI3TI",
            authDomain: "msmcrm-g24k37.firebaseapp.com",
            projectId: "msmcrm-g24k37",
            storageBucket: "msmcrm-g24k37.firebasestorage.app",
            messagingSenderId: "36397348687",
            appId: "1:36397348687:web:b8f120e3acf761ef09773a"));
  } else {
    await Firebase.initializeApp();
  }
}
