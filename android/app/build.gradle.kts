plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// CI 通过环境变量注入正式签名；本地完全未配置时保留 debug 回退。
val releaseSigningVariables = mapOf(
    "ANDROID_KEYSTORE_PATH" to System.getenv("ANDROID_KEYSTORE_PATH"),
    "ANDROID_KEYSTORE_PASSWORD" to System.getenv("ANDROID_KEYSTORE_PASSWORD"),
    "ANDROID_KEY_ALIAS" to System.getenv("ANDROID_KEY_ALIAS"),
    "ANDROID_KEY_PASSWORD" to System.getenv("ANDROID_KEY_PASSWORD"),
)
val configuredReleaseSigningVariableCount =
    releaseSigningVariables.values.count { !it.isNullOrBlank() }
val hasReleaseSigning =
    configuredReleaseSigningVariableCount == releaseSigningVariables.size
require(configuredReleaseSigningVariableCount == 0 || hasReleaseSigning) {
    val missingVariables =
        releaseSigningVariables
            .filterValues { it.isNullOrBlank() }
            .keys
            .joinToString()
    "发布签名配置不完整，缺少环境变量：$missingVariables"
}
val releaseKeystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
val legacyPackaging = System.getenv("ANDROID_LEGACY_PACKAGING") == "true"

android {
    namespace = "com.zhao.serial.dbg"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.zhao.serial.dbg"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(requireNotNull(releaseKeystorePath))
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
                enableV4Signing = false
            }
        }
    }

    packaging {
        if (legacyPackaging) {
            jniLibs {
                useLegacyPackaging = true
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
