import 'package:flutter/material.dart';
import 'package:full_map_use/Screen/Map_Screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Map_Screen(),
    );
  }
}
