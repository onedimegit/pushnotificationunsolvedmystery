import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:demok/loginpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Colors.orangeAccent, accentColor: Colors.pinkAccent),
      home: LoginPage(),
    ); //yes completely flawlessly so yes this is amazing ando i think this is going to be great.
  }
}
