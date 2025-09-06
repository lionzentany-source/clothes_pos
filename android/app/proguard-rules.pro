# Keep protobuf and gRPC classes used by google_speech
-keep class com.google.protobuf.** { *; }
-keep class io.grpc.** { *; }
-keep class javax.annotation.** { *; }
-dontwarn javax.annotation.**

# Flutter & Dart reflection safety (usually handled by default proguard file)
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }

# sqflite and ffi
-keep class androidx.sqlite.** { *; }
-keep class org.sqlite.** { *; }

# Prevent obfuscation of Activity names
-keep class **.MainActivity { *; }

# Play Core (deferred components) keep to avoid R8 missing class errors
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Tink (google crypto) annotations referenced indirectly
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }

# Reduce logging in release (optional)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
