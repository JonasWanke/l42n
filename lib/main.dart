import 'package:flutter/material.dart';
import 'package:l42n/choose_directory_page.dart';

import 'l42n_app.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return L42nApp(
      child: ChooseDirectoryPage(),
    );
  }
}
