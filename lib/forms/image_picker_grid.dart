import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memo_places_mobile/toasts.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

/// 3-slot grid of 96 px thumbnails with an add tile and per-image remove.
class ImagePickerGrid extends StatelessWidget {
  static const maxImages = 3;
  static const maxImageBytes = 10 * 1024 * 1024;

  final List<File> images;
  final VoidCallback onChanged;

  const ImagePickerGrid(
      {super.key, required this.images, required this.onChanged});

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage(
        limit: maxImages - images.length, imageQuality: 50);
    var rejected = false;
    for (final image in picked) {
      if (images.length >= maxImages) break;
      final file = File(image.path);
      if (await file.length() > maxImageBytes) {
        rejected = true;
        continue;
      }
      images.add(file);
    }
    if (rejected) showErrorToast(LocaleKeys.image_too_large.tr());
    if (picked.isNotEmpty) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < images.length; i++)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  images[i],
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () {
                    images.removeAt(i);
                    onChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        if (images.length < maxImages)
          InkWell(
            onTap: _pick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(Icons.add_a_photo_outlined,
                  color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
