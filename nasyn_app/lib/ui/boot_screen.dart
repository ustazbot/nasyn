import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/app_locale.dart';
import '../i18n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo-nasyn.png', width: 160),
            const SizedBox(height: 16),
            Text(
              AppStrings.of('tagline', AppLocale.bm),
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
