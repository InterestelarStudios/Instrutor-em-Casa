# ProGuard and R8 rules for Flutter and Google ML Kit

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google ML Kit Text Recognition (suppress missing optional language recognizers)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.**

# Google Play Core (deferred components)
-dontwarn com.google.android.play.core.**

# ML Kit keep rules
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
