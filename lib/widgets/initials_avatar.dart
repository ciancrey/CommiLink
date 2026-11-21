import 'package:flutter/material.dart';

import '../models/service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// NEW WIDGET · Round avatar: profile photo if there is one, otherwise the
/// person's initials on a color picked from their name (like the Figma
/// Messages / Network lists).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 52,
  });

  final String name;
  final String? imageUrl;
  final double size;

  static const List<Color> _palette = [
    AppColors.wine700,
    Color(0xFF2F7D5B), // green
    Color(0xFF6B4BA1), // purple
    Color(0xFFEFB988), // peach
    Color(0xFF8C2A4B), // wine 500
  ];

  Color get _color {
    var hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final bg = _color;
    final fg = bg == const Color(0xFFEFB988) ? AppColors.wine900 : Colors.white;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _letters(fg),
            )
          : _letters(fg),
    );
  }

  Widget _letters(Color fg) => Text(
        initialsOf(name),
        style: AppText.label14.copyWith(color: fg, fontSize: size * 0.3),
      );
}
