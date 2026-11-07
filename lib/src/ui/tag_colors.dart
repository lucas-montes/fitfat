import 'package:flutter/material.dart';

/// Deterministic, readable color pairs (background, foreground) derived from a
/// tag's text. Free-form planner tags get a stable color without storing any
/// per-tag color, so the same tag always looks the same across sessions.
final class TagColors {
  const TagColors._();

  static const _palette = <(Color, Color)>[
    (Color(0xFFE3F2FD), Color(0xFF0D47A1)), // blue
    (Color(0xFFE8F5E9), Color(0xFF1B5E20)), // green
    (Color(0xFFFFF8E1), Color(0xFF795548)), // amber/brown
    (Color(0xFFFCE4EC), Color(0xFF880E4F)), // pink
    (Color(0xFFF3E5F5), Color(0xFF4A148C)), // purple
    (Color(0xFFE0F2F1), Color(0xFF004D40)), // teal
    (Color(0xFFFBE9E7), Color(0xFFBF360C)), // deep orange
    (Color(0xFFECEFF1), Color(0xFF263238)), // blue-grey
  ];

  /// Returns `(background, foreground)` colors for [tag].
  static (Color, Color) forTag(String tag) {
    final index = tag.hashCode.abs() % _palette.length;
    return _palette[index];
  }
}
