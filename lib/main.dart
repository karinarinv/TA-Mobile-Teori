import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

// This is a basic Flutter application that displays "Hello World!" in the center of the screen.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
