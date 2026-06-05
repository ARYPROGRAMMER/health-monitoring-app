import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Circular avatar: network photo when available, otherwise a bordered glyph.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({this.photoUrl, this.size = 42, this.onTap, super.key});

  final String? photoUrl;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.elevatedCard,
        border: Border.all(color: tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _glyph(tokens),
            )
          : _glyph(tokens),
    );

    if (onTap == null) return inner;
    return GestureDetector(onTap: onTap, child: inner);
  }

  Widget _glyph(AppTokens tokens) => Icon(
    Icons.person_outline_rounded,
    size: size * 0.52,
    color: tokens.textMuted,
  );
}
