import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  final String name;
  final int age;

  const Profile({required this.name, required this.age});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(name), Text("Age: $age")]);
  }
}

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: Profile(name: "Ojasv", age: 19)),
      ),
    ), 
  );
}
