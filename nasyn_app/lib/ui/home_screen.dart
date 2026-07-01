import 'package:flutter/material.dart';

import '../audio/audio_cue_resolver.dart';
import '../prayer/prayer_config.dart';
import 'prayer_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerType _selectedType = PrayerType.zuhur;
  AssistanceLevel _selectedLevel = AssistanceLevel.fullRecite;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NASYN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Pilih Solat'),
            DropdownButton<PrayerType>(
              value: _selectedType,
              items: PrayerType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(prayerConfigs[t]!.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),
            const Text('Tahap Bantuan'),
            RadioListTile<AssistanceLevel>(
              title: const Text('Takbir Only'),
              value: AssistanceLevel.takbirOnly,
              groupValue: _selectedLevel,
              onChanged: (value) => setState(() => _selectedLevel = value!),
            ),
            RadioListTile<AssistanceLevel>(
              title: const Text('Panduan Posisi'),
              value: AssistanceLevel.panduanPosisi,
              groupValue: _selectedLevel,
              onChanged: (value) => setState(() => _selectedLevel = value!),
            ),
            RadioListTile<AssistanceLevel>(
              title: const Text('Full Recite'),
              value: AssistanceLevel.fullRecite,
              groupValue: _selectedLevel,
              onChanged: (value) => setState(() => _selectedLevel = value!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PrayerSessionScreen(
                    prayerType: _selectedType,
                    level: _selectedLevel,
                  ),
                ));
              },
              child: const Text('Mula'),
            ),
          ],
        ),
      ),
    );
  }
}
