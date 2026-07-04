import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/formWidgets/customButtonWithIcon.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class ImageInput extends StatefulWidget {
  final List<File> selectedImages;
  final void Function() onImageAdd;
  const ImageInput(
      {super.key, required this.selectedImages, required this.onImageAdd});

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      child: CustomButtonWithIcon(
        icon: Icons.photo_size_select_actual_rounded,
        text: LocaleKeys.select_pictures.tr(),
        onPressed: widget.onImageAdd,
      ),
    );
  }
}
