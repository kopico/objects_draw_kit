import 'package:flutter/material.dart';

import 'package:objects_draw_kit/pages/home.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  runApp(WebApp());
}

class WebApp extends StatefulWidget {
  const WebApp({Key? key}) : super(key: key);

  @override
  _WebAppState createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Error initializing firebase web app. ${snapshot.error}");
          return ErrorWidget.withDetails(message: "Error initializing firebase");
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return ObjectsDrawKit();
        }
        return const CircularProgressIndicator();
      },
    );
  }
}


class ObjectsDrawKit extends StatelessWidget {
  ObjectsDrawKit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Objects Draw Kit',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      debugShowCheckedModeBanner: false,
      home: Home(title: 'Objects Draw Kit'),
    );
  }
}

