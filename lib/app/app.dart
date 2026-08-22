import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class SoviApp extends StatelessWidget {
  const SoviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOVI - Secure Acoustic File Transfer',
      debugShowCheckedModeBanner: false,
      theme: SoviTheme.darkTheme,
      home: const MainNavigationWrapper(),
    );
  }
}
