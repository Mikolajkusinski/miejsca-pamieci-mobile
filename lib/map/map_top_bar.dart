import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

/// Floating search pill: app glyph, place search, profile avatar.
class MapTopBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onAvatarTap;

  /// First letter of the username; null renders the guest icon.
  final String? userInitial;

  const MapTopBar({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.onAvatarTap,
    this.userInitial,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: LocaleKeys.search_places.tr(),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primary,
              child: userInitial != null
                  ? Text(
                      userInitial!.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    )
                  : const Icon(Icons.person_outline,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
