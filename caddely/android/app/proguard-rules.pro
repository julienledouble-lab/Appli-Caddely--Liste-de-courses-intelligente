# ML Kit - keep all classes (internal DI uses reflection on class names)
-keep class com.google.mlkit.** { *; }
-keepattributes *Annotation*

# ML Kit optional language modules (not bundled - suppress warnings only)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
