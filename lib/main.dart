import 'package:flutter/material.dart';
import 'widgets/main_menu_widget.dart';
import 'theme/theme.dart'; // Import the theme file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: appTheme, // Apply the custom theme here
      home: MainMenuWidget(), // Use the MainMenuWidget as the home page
    );
  }
}
