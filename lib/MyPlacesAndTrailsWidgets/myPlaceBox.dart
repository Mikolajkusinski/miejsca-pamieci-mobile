import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Objects/shortPlace.dart';

class MyPlaceBox extends StatelessWidget {
  final ShortPlace place;

  const MyPlaceBox({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        border: Border(
          bottom: BorderSide(
              width: 4, color: Theme.of(context).colorScheme.tertiary),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: !place.verified ? Colors.grey.shade500 : Colors.green,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  place.placeName,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
