import 'package:flutter/material.dart';
import 'package:markdown_editor/pages/home_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(title: "Fleet Manager"),
      debugShowCheckedModeBanner: false,
    );
  }
}
