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
            val keystorePath = (System.getenv("MOVI_KEYSTORE")
                ?: project.findProperty("MOVI_KEYSTORE") as String?)
                ?: "keystore/movi-upload.jks"

            // Gérer les chemins absolus et relatifs correctement
            val keystoreFile = if (keystorePath != null) {
                val normalizedPath = keystorePath.replace("\\", "/")
                // Détecter si c'est un chemin absolu (Windows avec : ou Unix avec /)
                if (normalizedPath.contains(":") || (normalizedPath.startsWith("/") && !normalizedPath.startsWith("./"))) {
                    // Chemin absolu
                    file(normalizedPath)
                } else {
                    // Chemin relatif depuis le répertoire du module app (android/app)
                    file(normalizedPath)
                }
            } else {
                file("keystore/movi-upload.jks")
            }

            storeFile = keystoreFile
            storePassword = System.getenv("MOVI_STORE_PASSWORD")
                ?: (project.findProperty("MOVI_STORE_PASSWORD") as String?)
            keyAlias = System.getenv("MOVI_ALIAS")
                ?: (project.findProperty("MOVI_ALIAS") as String?)
            keyPassword = System.getenv("MOVI_KEY_PASSWORD")
                ?: (project.findProperty("MOVI_KEY_PASSWORD") as String?)
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
