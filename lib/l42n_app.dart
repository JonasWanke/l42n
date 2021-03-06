import 'package:flutter/material.dart';

class L42nApp extends StatelessWidget {
  const L42nApp({@required this.child}) : assert(child != null);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        brightness: Brightness.light,
        primarySwatch: Colors.purple,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        applyElevationOverlayColor: true,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.dark(
          surface: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          color: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: child,
    );
  }
}
