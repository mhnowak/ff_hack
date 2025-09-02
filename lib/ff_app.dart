import 'package:ff_hack/presentation/screens/badge_screen.dart';
import 'package:flutter/material.dart';

class FFApp extends StatelessWidget {
  const FFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const BadgeScreen());
  }
}
