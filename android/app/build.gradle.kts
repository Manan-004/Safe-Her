plugins {
    id("com.android.application")
    id("kotlin-android")

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.safe_her"

    // ✅ Fixed versions
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.safe_her"
        minSdk = 23         // Firebase requires minSdk ≥ 23
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        // ✅ This defines the variable used in your AndroidManifest.xml
        manifestPlaceholders["applicationName"] = "android.app.Application"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM ensures compatible versions
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // Firebase Authentication
    implementation("com.google.firebase:firebase-auth-ktx")

    // Add other Firebase dependencies if needed
    // implementation("com.google.firebase:firebase-database-ktx")
    // implementation("com.google.firebase:firebase-firestore-ktx")
}