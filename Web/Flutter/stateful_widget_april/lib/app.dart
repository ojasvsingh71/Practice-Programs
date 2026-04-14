import 'package:flutter/material.dart';

class Fun extends StatefulWidget {
  _FunState createState() => _FunState();
}

class _FunState extends State<Fun> {
  String message = "Kuchu kuchu !!!";

  @override
  Widget build(BuildContext context) {
    return Column(children: [
        Text(message),
        TextField()
      ],
    );
  }
}
