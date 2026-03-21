import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("My First App")),
        body: Column(
          children: [
            Text("Hi Ojasv", style: TextStyle(fontSize: 30)),
            Text("Welcome", style: TextStyle(fontSize: 20)),

            ElevatedButton(
              onPressed: () {
                print("Clicked");
              },
              child: Text(
                "Dont Click me",
                style: TextStyle(color: Colors.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
