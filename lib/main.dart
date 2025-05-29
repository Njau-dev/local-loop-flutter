import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:local_loop/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Loop',
      home: Scaffold(
        appBar: AppBar(title: const Text('Local Loop'), centerTitle: true),
        body: const Center(child: Text('Welcome to Local Loop!')),
      ),
    );
  }
}
