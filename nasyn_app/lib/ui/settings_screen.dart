import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_locale.dart';
import '../i18n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        title: Text(AppStrings.of('setting', locale)),
      ),
      body: Center(
        child: Text(
          AppStrings.of('settingsComingSoon', locale),
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}
