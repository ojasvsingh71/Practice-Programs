import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:TapExample()
    );
  }
}

class TapExample extends StatefulWidget {
  @override
  _TapExampleState createState() => _TapExampleState();
}

class _TapExampleState extends State<TapExample> {
  String message = "Not clicked";

  void handleTap() {
    setState(() {
      message = 'Button Clicked!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message),
        ElevatedButton(onPressed: handleTap, child: Text("Click me!")),
      ],
    );
  }
}
