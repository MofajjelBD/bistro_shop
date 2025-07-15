plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    kotlin("android")
    id("com.google.gms.google-services") 
}
dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:33.15.0"))


  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  // https://firebase.google.com/docs/android/setup#available-libraries
  implementation("androidx.multidex:multidex:2.0.1")
}

android {
    namespace = "com.example.bistro_shop"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.bistro_shop"
        minSdk = 23 // ✅ updated
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true 
    }

    ndkVersion = "27.0.12077973" // ✅ added

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}
