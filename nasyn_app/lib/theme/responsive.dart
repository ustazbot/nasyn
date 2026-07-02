import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static double scale(BuildContext context, {double min = 0.8, double max = 1.2}) {
    final width = MediaQuery.of(context).size.width;
    return (width / 360.0).clamp(min, max);
  }
}
