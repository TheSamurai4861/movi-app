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
        val keystorePath = project.findProperty("MOVI_KEYSTORE") as String?
        val storePass = project.findProperty("MOVI_STORE_PASSWORD") as String?
        val alias = project.findProperty("MOVI_ALIAS") as String?
        val keyPass = project.findProperty("MOVI_KEY_PASSWORD") as String?
        if (keystorePath != null && storePass != null && alias != null && keyPass != null) {
            create("release") {
                storeFile = file(keystorePath)
                storePassword = storePass
                keyAlias = alias
                keyPassword = keyPass
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            // Option: signer aussi les debug si tu veux installer rapidement des variants release-like
            // signingConfig = signingConfigs.getByName("release")
        }
        getByName("release") {
            val sc = signingConfigs.findByName("release")
            if (sc != null) {
                signingConfig = sc
            }
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
