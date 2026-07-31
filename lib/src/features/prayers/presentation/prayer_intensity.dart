import 'package:flutter/material.dart';

/// Shared color scale for prayer completion heatmaps.
///
/// A missing record is kept visually distinct from a recorded zero so the
/// history view can distinguish "not logged" from "logged, none completed".
class PrayerIntensityColors {
  const PrayerIntensityColors._();

  static const noRecord = Color(0xFF28283E);
  static const zero = Color(0xFF454653);
  static const one = Color(0xFFD94F5C);
  static const two = Color(0xFFE8794B);
  static const three = Color(0xFFF0B44A);
  static const four = Color(0xFF83C96B);
  static const five = Color(0xFF39B86A);

  static Color forCount(int? completedCount) {
    return switch (completedCount) {
      null => noRecord,
      0 => zero,
      1 => one,
      2 => two,
      3 => three,
      4 => four,
      _ => five,
    };
  }
}
