import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tp_bank/core/providers/user_provider.dart';
import 'package:tp_bank/screens/home_screen.dart';
import 'package:tp_bank/screens/login_screen.dart';
import 'package:tp_bank/app.dart';

class MyAppView extends StatelessWidget {
   final bool isLogged;
  const MyAppView({super.key,required this.isLogged});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Thêm các provider khác ở đây nếu cần
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TP_Bank',
        theme: ThemeData(
          colorScheme: ColorScheme.light(
            primary: Color.fromARGB(218, 104, 5, 211),
            secondary: Color.fromARGB(217, 105, 5, 211),
            tertiary: Color.fromARGB(255, 213, 162, 255),
            outline: Colors.grey,
          ),
        ),
       home: isLogged ? HomeScreen() : LoginScreen(),
      ),
    );
  }
}
