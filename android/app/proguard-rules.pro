# Google Maps renderer classes are resolved reflectively.
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Keep Flutter's generated plugin registrant (reflection from the engine).
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
