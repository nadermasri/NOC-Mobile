# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native channel handler
-keep class com.pocketnoc.pocket_noc.** { *; }

# Gson / JSON
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Play Core (referenced by Flutter engine but not always present)
-dontwarn com.google.android.play.core.**
