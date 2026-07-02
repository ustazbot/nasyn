import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const display = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.bold,
    color: AppColors.lightText,
  );

  static const body = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: AppColors.lightText,
  );

  static const label = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.normal,
    color: AppColors.lightText,
  );
}
