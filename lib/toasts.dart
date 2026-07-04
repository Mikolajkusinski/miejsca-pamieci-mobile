import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showSuccesToast(String msg) {
  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: const Color.fromARGB(200, 76, 175, 79),
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

void showErrorToast(String msg) {
  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: const Color.fromARGB(197, 230, 45, 31),
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
