import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

/// User avatar widget — shows photo or colored circle with initial.
class UserAvatar extends StatelessWidget {
  final String name;
  final String colorHex;
  final String? photoUrl;
  final double size;

  const UserAvatar({super.key, required this.name, required this.colorHex, this.photoUrl,
    this.size = AppConstants.avatarMedium});

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.fromHex(colorHex);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: bgColor.withValues(alpha: 0.3), width: 2),
      ),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(child: CachedNetworkImage(imageUrl: photoUrl!, fit: BoxFit.cover, width: size, height: size,
              placeholder: (_, _) => _initialWidget(initial), errorWidget: (_, _, _) => _initialWidget(initial)))
          : _initialWidget(initial),
    );
  }

  Widget _initialWidget(String initial) {
    return Center(child: Text(initial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
      fontSize: size * 0.4)));
  }
}
