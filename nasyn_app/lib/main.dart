import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: NasynApp()));
}

class NasynApp extends StatelessWidget {
  const NasynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NASYN',
      home: const HomeScreen(),
    );
  }
}
