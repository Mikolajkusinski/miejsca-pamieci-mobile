import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class SliderWithDots extends StatefulWidget {
  final List<String> images;

  const SliderWithDots({required this.images, super.key});

  @override
  State<SliderWithDots> createState() => _SliderWithDotsState();
}

class _SliderWithDotsState extends State<SliderWithDots> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> imageSliders = widget.images
        .map((image) => Container(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  width: 1000,
                ),
              ),
            ))
        .toList();

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
