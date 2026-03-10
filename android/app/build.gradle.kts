plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.little_genius"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Keeps desugaring enabled for the notifications plugin
        isCoreLibraryDesugaringEnabled = true
        
        // Ensure both are explicitly set to VERSION_11
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // Standardize the jvmTarget string to "11"
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.little_genius"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        multiDexEnabled = true 
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
    // This library version is compatible with Java 11
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}