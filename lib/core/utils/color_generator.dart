import 'dart:math';
import '../constants/app_colors.dart';

/// Utility for assigning unique colors to users at registration time.
/// Colors are picked randomly from the predefined palette.
class ColorGenerator {
  ColorGenerator._();

  static final Random _random = Random();

  /// Returns a random color hex string from the predefined user color list.
  /// Optionally pass [excludeColors] to avoid assigning a color
  /// already used by other members in the same group.
  static String getRandomColorHex({List<String>? excludeColors}) {
    final available = List<String>.from(AppColors.userColorHexes);

    // Remove any colors that should be excluded
    if (excludeColors != null && excludeColors.isNotEmpty) {
      available.removeWhere((c) => excludeColors.contains(c));
    }

    // If all colors are taken, just pick from the full list (allow duplicates)
    if (available.isEmpty) {
      return AppColors.userColorHexes[_random.nextInt(AppColors.userColorHexes.length)];
    }

    return available[_random.nextInt(available.length)];
  }
}
