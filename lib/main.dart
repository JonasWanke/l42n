import 'package:flutter/material.dart';

import 'l42n_app.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return L42nApp(
      child: Scaffold(
        appBar: AppBar(
          title: Text('L42n'),
        ),
        body: Container(),
      ),
    );
  }
}
