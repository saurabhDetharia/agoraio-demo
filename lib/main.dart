import 'package:agora_demo/screens/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agora Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const HomePage(title: 'Agora.io'),
    );
  }
}
