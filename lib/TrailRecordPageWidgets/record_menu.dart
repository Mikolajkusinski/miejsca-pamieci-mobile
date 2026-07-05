import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class RecordMenu extends StatelessWidget {
  final String distance;
  final bool isRecording;
  final String time;
  final void Function() startRecording;
  final void Function() endRecording;

  const RecordMenu(
      {super.key,
      required this.distance,
      required this.isRecording,
      required this.time,
      required this.startRecording,
      required this.endRecording});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasDistance =
        (double.tryParse(distance.split(' ').first) ?? 0.0) > 0.0;

    return Positioned(
      right: 0,
      left: 0,
      bottom: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: textTheme.titleLarge!
                      .copyWith(color: scheme.primary),
                ),
                Text(
                  LocaleKeys.distance.tr(namedArgs: {'distance': distance}),
                  style: textTheme.titleMedium!
                      .copyWith(color: scheme.onSurfaceVariant, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            isRecording
                ? FilledButton(
                    onPressed: hasDistance ? endRecording : null,
                    child: Text(LocaleKeys.stop_save.tr()),
                  )
                : FilledButton(
                    onPressed: startRecording,
                    child: Text(LocaleKeys.start.tr()),
                  ),
          ],
        ),
      ),
    );
  }
}
