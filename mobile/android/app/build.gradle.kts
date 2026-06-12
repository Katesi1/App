import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Đọc key.properties nếu tồn tại (dùng cho release signing)
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.halong24h.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // flutter_local_notifications cần Java 8+ API desugaring (vd
        // java.time) trên Android API < 26.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.halong24h.app"
        // camera_android_camerax 0.6.30 yêu cầu API ≥ 23 (Android 6.0).
        // google_mlkit_commons chỉ cần API 21 — camera là giới hạn thật sự.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        // Flutter 3.35+ mặc định targetSdk=36 (Android 16 preview) — pin về 35
        // để tránh Google Play hạn chế phân phối trên thiết bị chưa tương thích API 36.
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (!keyPropertiesFile.exists()) {
                throw GradleException(
                    "key.properties không tồn tại — không thể build release APK/AAB có chữ ký hợp lệ. " +
                    "Tạo file key.properties với storeFile, storePassword, keyAlias, keyPassword."
                )
            }
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required by flutter_local_notifications when isCoreLibraryDesugaringEnabled = true.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

// Flutter 3.35.x bug: flutter pub get writes integration_test (dev_dependency=true) vào
// GeneratedPluginRegistrant.java, gây lỗi compile khi build release vì class không tồn tại.
// Hook này strip entry đó ra trước khi Java compiler chạy.
afterEvaluate {
    tasks.named("compileReleaseJavaWithJavac").configure {
        doFirst {
            val registrantFile = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
            if (registrantFile.exists()) {
                val original = registrantFile.readText()
                val fixed = original.replace(
                    Regex("""\n\s+try \{\n[^\n]*integration_test[^\n]*\n\s+\} catch \(Exception e\) \{\n[^\n]*integration_test[^\n]*\n\s+\}"""),
                    ""
                )
                if (fixed != original) registrantFile.writeText(fixed)
            }
        }
    }
}
