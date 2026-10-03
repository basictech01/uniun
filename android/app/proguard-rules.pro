# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core (for deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# MediaPipe - keep everything (flutter_gemma)
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# MediaPipe specific proto classes missing in tasks-genai
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto*
-dontwarn com.google.mediapipe.proto.GraphTemplateProto*

# Protocol Buffers - keep everything
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Kotlinx coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# google_mlkit_image_labeling: the Firebase-hosted custom-model branch
# references linkfirebase, which build.gradle.kts excludes. UNIUN never takes
# that branch (base on-device labeler only).
-dontwarn com.google.mlkit.linkfirebase.**

# google_mlkit_text_recognition declares the Chinese/Japanese/Korean
# recognisers compileOnly and references them from a switch UNIUN never takes
# (Latin + Devanagari only). Without these, R8 fails every release build.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
