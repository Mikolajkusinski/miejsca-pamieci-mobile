import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/formWidgets/customButton.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class RecordMenu extends StatefulWidget {
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
  State<StatefulWidget> createState() => _RecordMenuState();
}

class _RecordMenuState extends State<RecordMenu> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      left: 0,
      bottom: 0,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color.fromARGB(202, 0, 0, 0),
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.time,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.scrim,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  LocaleKeys.distance
                      .tr(namedArgs: {'distance': widget.distance}),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.scrim,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
            widget.isRecording
                ? CustomButton(
                    onPressed: double.parse(widget.distance) == 0.0
                        ? () {}
                        : widget.endRecording,
                    text: LocaleKeys.stop_save.tr())
                : CustomButton(
                    onPressed: widget.startRecording,
                    text: LocaleKeys.start.tr())
          ],
        ),
      ),
    );
  }
}
