import 'package:flutter/material.dart';
import 'package:tp_bank/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isLogged = false;

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    isLogged = token != null;
  } catch (e) {
    // Trong release có lỗi SharedPreferences thì app vẫn không crash
    debugPrint('Error loading SharedPreferences: $e');
  }

  runApp(MyApp(isLogged: isLogged));
}
