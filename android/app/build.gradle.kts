plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mess_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
    jvmTarget = JavaVersion.VERSION_17.toString()
    }


    defaultConfig {
        applicationId = "com.example.mess_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    debugImplementation("io.flutter:flutter_embedding_debug:1.0.0-425cfb54d01a9472b3e81d9e76fd63a4a44cfbcb")
    profileImplementation("io.flutter:flutter_embedding_profile:1.0.0-425cfb54d01a9472b3e81d9e76fd63a4a44cfbcb")
    releaseImplementation("io.flutter:flutter_embedding_release:1.0.0-425cfb54d01a9472b3e81d9e76fd63a4a44cfbcb")
}

flutter {
    source = "../.."
}
