plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle plugin must be applied after Android and Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.q_auto_inventory_new"
    compileSdk = 35  // you can use flutter.compileSdkVersion if preferred
    ndkVersion = "27.0.12077973" // force latest NDK required by Firebase plugins

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // Ensure all Kotlin compilation uses JDK 17
    kotlin {
        jvmToolchain(17)
    }

    defaultConfig {
        applicationId = "com.example.q_auto_inventory_new"
        minSdk = 21  // or flutter.minSdkVersion
        targetSdk = 34  // or flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // replace with real signing for production
        }
    }
}

flutter {
    source = "../.."
}
