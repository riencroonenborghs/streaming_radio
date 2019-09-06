import "package:flutter/material.dart";
import "package:StreamingRadio/pages/pages.dart";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Streaming Radio",
      theme: ThemeData(
        primaryColor: Colors.lightBlue[900]
      ),
      home: MainPage()
    );
  }
}



