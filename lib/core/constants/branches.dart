import 'package:flutter/material.dart';

/// Fixed list of available branches in the Palestinian Tawjihi system
class Branches {
  const Branches._();

  static const List<String> all = [
    'علمي',
    'أدبي',
    'شرعي',
    'صناعي',
  ];

  /// Brand color per branch — vivid but modern tones used as the accent across
  /// the exam experience so each student's screens feel cohesive.
  static Color color(String branch) => switch (branch) {
        'علمي' => const Color(0xFF2563EB), // blue
        'أدبي' => const Color(0xFF16A34A), // green
        'شرعي' => const Color(0xFF7C3AED), // violet
        'صناعي' => const Color(0xFFEA580C), // orange
        _ => const Color(0xFF4F46E5), // indigo default
      };
}
