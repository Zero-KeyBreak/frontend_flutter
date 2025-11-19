import 'package:flutter/material.dart';
import 'app_view.dart';

class MyApp extends StatelessWidget {
   final bool isLogged;
  const MyApp({super.key, required this.isLogged});

  @override
  Widget build(BuildContext context) {
    return MyAppView(isLogged: isLogged,);
  }
}
