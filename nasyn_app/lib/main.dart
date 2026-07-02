import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/boot_screen.dart';

void main() {
  runApp(const ProviderScope(child: NasynApp()));
}

class NasynApp extends StatelessWidget {
  const NasynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NASYN',
      theme: ThemeData.dark(),
      home: const BootScreen(),
    );
  }
}
