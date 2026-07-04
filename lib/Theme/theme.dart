import 'package:flutter/material.dart';
import 'package:memo_places_mobile/Theme/colors.dart';

var lightTheme = ThemeData().copyWith(
  colorScheme: lightColorScheme,
  scaffoldBackgroundColor: lightColorScheme.surface,
  appBarTheme: const AppBarTheme().copyWith(
    centerTitle: true,
    surfaceTintColor: lightColorScheme.tertiary,
    backgroundColor: lightColorScheme.surface,
    titleTextStyle: TextStyle(
      color: lightColorScheme.onSurface,
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
      unselectedItemColor: lightColorScheme.onSurface,
      selectedItemColor: lightColorScheme.scrim),
  dialogTheme: DialogThemeData(surfaceTintColor: lightColorScheme.scrim),
);

var darkTheme = ThemeData.dark().copyWith(
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: darkColorScheme.surface,
  appBarTheme: const AppBarTheme().copyWith(
    centerTitle: true,
    surfaceTintColor: darkColorScheme.tertiary,
    backgroundColor: darkColorScheme.surface,
    titleTextStyle: TextStyle(
      color: darkColorScheme.onSurface,
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
      unselectedItemColor: darkColorScheme.onSurface,
      selectedItemColor: darkColorScheme.scrim),
  dialogTheme: DialogThemeData(surfaceTintColor: darkColorScheme.scrim),
);
