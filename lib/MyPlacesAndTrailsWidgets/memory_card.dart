import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/theme/app_colors.dart';

/// List card for a user's place or trail: 56 px thumbnail, title,
/// period chip and verification badge.
class MemoryCard extends StatelessWidget {
  final String title;
  final String? periodLabel;
  final bool verified;
  final Future<List<String>>? imagesFuture;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const MemoryCard({
    super.key,
    required this.title,
    required this.verified,
    required this.onTap,
    this.periodLabel,
    this.imagesFuture,
    this.fallbackIcon = Icons.place_outlined,
  });

  Widget _thumbnail(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(fallbackIcon, color: scheme.onSurfaceVariant),
    );
    if (imagesFuture == null) return placeholder;
    return FutureBuilder<List<String>>(
      future: imagesFuture,
      builder: (context, snapshot) {
        final images = snapshot.data;
        if (images == null || images.isEmpty) return placeholder;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            images.first,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _thumbnail(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium!.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (periodLabel != null && periodLabel!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Text(
                            periodLabel!.tr(),
                            style: textTheme.bodySmall!
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                verified ? Icons.verified : Icons.pending_outlined,
                color:
                    verified ? AppColors.success : scheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
