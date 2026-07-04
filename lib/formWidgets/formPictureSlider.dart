import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class FormPictureSlider extends StatefulWidget {
  final List<File> images;
  final Function(int) onImageRemoved;

  const FormPictureSlider(
      {required this.images, required this.onImageRemoved, super.key});

  @override
  State<FormPictureSlider> createState() => _FormPictureSliderState();
}

class _FormPictureSliderState extends State<FormPictureSlider> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> imageSliders =
        widget.images.asMap().entries.map((entry) {
      final int index = entry.key;
      final File image = entry.value;
      return Container(
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(5.0)),
              child: Image.file(
                image,
                fit: BoxFit.cover,
                width: 1000,
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: GestureDetector(
                onTap: () {
                  widget.onImageRemoved(index);
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      children: [
        CarouselSlider(
          items: imageSliders,
          options: CarouselOptions(
              enableInfiniteScroll: false,
              aspectRatio: 2.0,
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.images.map((url) {
            int index = widget.images.indexOf(url);
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == index
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.secondary),
            );
          }).toList(),
        )
      ],
    );
  }
}
