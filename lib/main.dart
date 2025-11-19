import 'package:flutter/material.dart';
import 'package:tp_bank/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("token");
  runApp(MyApp(isLogged: token != null));
}
