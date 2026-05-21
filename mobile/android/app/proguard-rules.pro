# Flutter obfuscation — keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# JSON Serialization — keep classes annotated với @JsonSerializable (json_serializable)
# Dart/Flutter code bị obfuscate qua --obfuscate flag khi build; rules này áp dụng cho Java/Kotlin layer.
-keepattributes *Annotation*
-keepattributes Signature

# Firebase — giữ nguyên để Crashlytics symbolication hoạt động
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# ML Kit — Text Recognition + Face Detection + Barcode Scanning
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# image_picker / photo_view
-keep class io.flutter.plugins.imagepicker.** { *; }

# Prevent stripping of Flutter plugin registrant
-keep class com.halongtravel.halong24h.GeneratedPluginRegistrant { *; }

# Google Play Core (deferred components — Flutter uses these internally)
-dontwarn com.google.android.play.core.**

# Suppress warnings từ third-party libraries không liên quan
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
