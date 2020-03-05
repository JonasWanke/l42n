import 'package:flutter/material.dart';

class L42nApp extends StatelessWidget {
  const L42nApp({@required this.child}) : assert(child != null);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: child,
    );
  }
}
