import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mirror_view/auth.dart';
import 'package:mirror_view/mainpage.dart';
import 'package:mirror_view/tests.dart';

import 'firebase_options.dart';

late final FirebaseApp app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  /// runSpeechToTextWithGemini();

  deletePrompts();

  runApp(const MirrorViewApp());
}

/// APP LAYOUT AND IDEA
/// functions.dart -> all functionality and firebase connections are saved in here...
/// components.dart -> all components and widgets are placed in here
/// pages.dart -> all different pages the app navigates through are in here
/// main.dart -> the initial app

class MirrorViewApp extends StatelessWidget {
  const MirrorViewApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MirrorView',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: MainAppHandler(
        key: key,
      ),
    );
  }
}

class MainAppHandler extends StatefulWidget {
  const MainAppHandler({super.key});

  @override
  State<MainAppHandler> createState() => _MainAppHandlerState();
}

class _MainAppHandlerState extends State<MainAppHandler> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth auth = FirebaseAuth.instance;
    if (kIsWeb) {
      auth.setPersistence(Persistence.NONE);
    }
    auth.userChanges().listen((User? user) {
      print(user);
      if (user == null) {
        /// navigate to SignIn page...
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => SignInPage(
                  firebaseApp: app,
                )));
      } else {
        /// navigate to landing page...
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (contxt) => MainPage()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(),
    );
  }
}
