import 'package:flutter/material.dart';

/// All color constants used throughout the SplitSaathi app.
/// Never hardcode colors elsewhere — always reference this class.
class AppColors {
  AppColors._(); // Prevent instantiation

  // ─── Primary Palette ────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1); // Elegant Indigo
  static const Color primaryDark = Color(0xFF4F46E5); // Deep Indigo
  static const Color primaryLight = Color(0xFFEEF2FF); // Pale Indigo

  // ─── Secondary & Accent ─────────────────────────────────────
  static const Color secondary = Color(0xFFEC4899); // Sophisticated Pink
  static const Color accent = Color(0xFF10B981); // Emerald Green (Not Parrot)

  // ─── Backgrounds & Surfaces ─────────────────────────────────
  static const Color background = Color(0xFFF8FAFC); // Slate Gray Tint
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // ─── Semantic Colors ────────────────────────────────────────
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color success = Color(0xFF10B981); // Emerald Green

  // ─── Text Colors ────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8); // Slate 400

  // ─── Divider ────────────────────────────────────────────────
  static const Color divider = Color(0xFFE2E8F0); // Slate 200

  // ─── Shimmer ────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFF1F5F9);
  static const Color shimmerHighlight = Color(0xFFE2E8F0);

  // ─── User Unique Colors ─────────────────────────────────────
  static const List<Color> userColors = [
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF0EA5E9), // Sky
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
  ];

  /// Hex string versions for Firestore storage
  static const List<String> userColorHexes = [
    '#EF4444',
    '#F59E0B',
    '#10B981',
    '#0EA5E9',
    '#6366F1',
    '#8B5CF6',
    '#EC4899',
    '#F43F5E',
  ];

  // ─── Role Badge Colors ──────────────────────────────────────
  static const Color roleSuperAdmin = Color(0xFFF59E0B); // Amber
  static const Color roleAdmin = Color(0xFF6366F1); // Indigo
  static const Color roleEditor = Color(0xFF10B981); // Emerald
  static const Color roleViewer = Color(0xFF64748B); // Slate

  /// Converts a hex string (e.g., '#FF6B6B') to a Color object.
  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Converts a Color to a hex string (e.g., '#FF6B6B').
  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}
