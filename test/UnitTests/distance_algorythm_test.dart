import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

double calculateDistance(LatLng start, LatLng end) {
  const double earthRadius = 6371.0;

  double lat1 = start.latitude * pi / 180.0;
  double lon1 = start.longitude * pi / 180.0;
  double lat2 = end.latitude * pi / 180.0;
  double lon2 = end.longitude * pi / 180.0;

  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  double distance = earthRadius * c;
  return distance;
}

void main() {
  test('calculateDistance returns correct distance between Gdańsk and Warsaw',
      () {
    LatLng gdansk = const LatLng(54.3520, 18.6466);
    LatLng warsaw = const LatLng(52.2297, 21.0122);

    double distance = calculateDistance(gdansk, warsaw);

    expect(distance, closeTo(284.0, 1.0));
  });

  test('calculateDistance returns correct distance between Gdańsk and Kraków',
      () {
    LatLng gdansk = const LatLng(54.3520, 18.6466);
    LatLng krakow = const LatLng(50.0647, 19.9450);

    double distance = calculateDistance(gdansk, krakow);

    expect(distance, closeTo(485.0, 1.0));
  });

  test('calculateDistance returns zero distance for the same point in Gdańsk',
      () {
    LatLng gdansk = const LatLng(54.3520, 18.6466);

    double distance = calculateDistance(gdansk, gdansk);

    expect(distance, 0.0);
  });
}
