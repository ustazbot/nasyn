import 'package:flutter/material.dart';

import '../prayer/prayer_config.dart';
import 'home_screen.dart';

class SessionSummaryScreen extends StatelessWidget {
  final PrayerType prayerType;
  final int totalRakaat;

  const SessionSummaryScreen({
    super.key,
    required this.prayerType,
    required this.totalRakaat,
  });

  @override
  Widget build(BuildContext context) {
    final config = prayerConfigs[prayerType]!;
    return Scaffold(
      appBar: AppBar(title: const Text('Selesai')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${config.displayName} selesai'),
            Text('Rakaat: $totalRakaat / $totalRakaat'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }
}
