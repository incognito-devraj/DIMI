import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─── Load signing credentials from android/key.properties ──────────────────
// key.properties is gitignored (see android/.gitignore). Back up the file and
// the keystore — losing them means you can never update the app.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "com.dimi.dimi_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // ⚠️  Never change this ID after publishing — it breaks Google sign-in,
        //     Supabase OAuth redirect, and any existing installs.
        applicationId = "com.dimi.dimi_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += "arm64-v8a"
        }
    }

    // ─── Signing ────────────────────────────────────────────────────────────
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            // R8 full-mode: shrinks, obfuscates, and optimises the Java/Kotlin
            // bytecode. Flutter's --obfuscate flag handles Dart obfuscation.
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    applicationVariants.all {
        outputs.all {
            (this as com.android.build.gradle.api.ApkVariantOutput).outputFileName = "DIMI.apk"
        }
    }

    packagingOptions {
        jniLibs {
            excludes += listOf(
                "**/armeabi-v7a/**",
                "**/x86/**",
                "**/x86_64/**",
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
