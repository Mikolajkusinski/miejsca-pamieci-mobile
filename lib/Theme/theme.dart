import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Theme/colors.dart';

var lightTheme = ThemeData().copyWith(
  colorScheme: lightColorScheme,
  scaffoldBackgroundColor: lightColorScheme.background,
  appBarTheme: const AppBarTheme().copyWith(
    centerTitle: true,
    surfaceTintColor: lightColorScheme.tertiary,
    backgroundColor: lightColorScheme.background,
    titleTextStyle: TextStyle(
      color: lightColorScheme.onBackground,
      fontWeight: FontWeight.bold,
      fontSize: 32,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData().copyWith(
      foregroundColor: lightColorScheme.scrim,
      backgroundColor: lightColorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28.0),
      )),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData().copyWith(
      backgroundColor: lightColorScheme.secondary,
      unselectedItemColor: lightColorScheme.onBackground,
      selectedItemColor: lightColorScheme.scrim),
  dialogTheme:
      const DialogTheme().copyWith(surfaceTintColor: lightColorScheme.scrim),
);

var darkTheme = ThemeData.dark().copyWith(
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: darkColorScheme.background,
  appBarTheme: const AppBarTheme().copyWith(
    centerTitle: true,
    surfaceTintColor: darkColorScheme.tertiary,
    backgroundColor: darkColorScheme.background,
    titleTextStyle: TextStyle(
      color: darkColorScheme.onBackground,
      fontWeight: FontWeight.bold,
      fontSize: 32,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData().copyWith(
      foregroundColor: darkColorScheme.scrim,
      backgroundColor: darkColorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28.0),
      )),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData().copyWith(
      backgroundColor: darkColorScheme.secondary,
      unselectedItemColor: darkColorScheme.onBackground,
      selectedItemColor: darkColorScheme.scrim),
  dialogTheme:
      const DialogTheme().copyWith(surfaceTintColor: darkColorScheme.scrim),
);
