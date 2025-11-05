plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.matteo.movi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.matteo.movi"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        buildConfig = true
    }

    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Movi Dev")
            buildConfigField("String", "FLAVOR_NAME", "\"dev\"")
        }
        create("stage") {
            dimension = "env"
            applicationIdSuffix = ".stage"
            versionNameSuffix = "-stage"
            resValue("string", "app_name", "Movi Stage")
            buildConfigField("String", "FLAVOR_NAME", "\"stage\"")
        }
        create("prod") {
            dimension = "env"
            // pas de suffix
            resValue("string", "app_name", "Movi")
            buildConfigField("String", "FLAVOR_NAME", "\"prod\"")
        }
    }


    signingConfigs {
        create("release") {
            val keystorePath = (project.findProperty("MOVI_KEYSTORE") as? String)
                ?: error("MOVI_KEYSTORE manquant (android/gradle.properties ou ~/.gradle/gradle.properties)")
            storeFile = file(keystorePath)
            storePassword = (project.findProperty("MOVI_STORE_PASSWORD") as? String)
                ?: error("MOVI_STORE_PASSWORD manquant")
            keyAlias = (project.findProperty("MOVI_ALIAS") as? String)
                ?: error("MOVI_ALIAS manquant")
            keyPassword = (project.findProperty("MOVI_KEY_PASSWORD") as? String)
                ?: error("MOVI_KEY_PASSWORD manquant")
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            // Option: signer aussi les debug si tu veux installer rapidement des variants release-like
            // signingConfig = signingConfigs.getByName("release")
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
