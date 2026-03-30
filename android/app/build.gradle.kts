plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val configuredKeystorePath = (System.getenv("MOVI_KEYSTORE")
    ?: project.findProperty("MOVI_KEYSTORE") as String?)
    ?.trim()
    ?.takeIf { it.isNotEmpty() }
val configuredStorePassword = (System.getenv("MOVI_STORE_PASSWORD")
    ?: project.findProperty("MOVI_STORE_PASSWORD") as String?)
    ?.trim()
    ?.takeIf { it.isNotEmpty() }
val configuredAlias = (System.getenv("MOVI_ALIAS")
    ?: project.findProperty("MOVI_ALIAS") as String?)
    ?.trim()
    ?.takeIf { it.isNotEmpty() }
val configuredKeyPassword = (System.getenv("MOVI_KEY_PASSWORD")
    ?: project.findProperty("MOVI_KEY_PASSWORD") as String?)
    ?.trim()
    ?.takeIf { it.isNotEmpty() }

fun resolveKeystoreFile(rawPath: String): File {
    val normalizedPath = rawPath.replace("\\", "/")
    val isAbsolutePath =
        normalizedPath.contains(":") ||
            (normalizedPath.startsWith("/") && !normalizedPath.startsWith("./"))

    val candidates = linkedSetOf<File>()
    if (isAbsolutePath) {
        candidates += file(normalizedPath)
    } else {
        candidates += file(normalizedPath)
        candidates += rootProject.file(normalizedPath)
        if (normalizedPath.startsWith("android/")) {
            candidates += rootProject.file(normalizedPath.removePrefix("android/"))
        } else {
            candidates += rootProject.file("app/$normalizedPath")
        }
    }

    return candidates.firstOrNull { it.exists() } ?: candidates.first()
}

val releaseKeystoreFile = configuredKeystorePath?.let(::resolveKeystoreFile)
val hasReleaseSigning =
    releaseKeystoreFile?.isFile == true &&
        configuredStorePassword != null &&
        configuredAlias != null &&
        configuredKeyPassword != null

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

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = releaseKeystoreFile
                storePassword = configuredStorePassword
                keyAlias = configuredAlias
                keyPassword = configuredKeyPassword
            }
        }
    }

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Movi Dev")
            buildConfigField("String", "FLAVOR_NAME", "\"dev\"")
            signingConfig = signingConfigs.getByName("debug")
        }
        create("stage") {
            dimension = "env"
            applicationIdSuffix = ".stage"
            versionNameSuffix = "-stage"
            resValue("string", "app_name", "Movi Stage")
            buildConfigField("String", "FLAVOR_NAME", "\"stage\"")
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        create("prod") {
            dimension = "env"
            // pas de suffix
            resValue("string", "app_name", "Movi")
            buildConfigField("String", "FLAVOR_NAME", "\"prod\"")
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
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
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
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

if (!hasReleaseSigning) {
    logger.warn(
        "Movi release keystore not found or incomplete. " +
            "devRelease/stageRelease will use debug signing. " +
            "Looked for: ${releaseKeystoreFile?.path ?: configuredKeystorePath ?: "MOVI_KEYSTORE not set"}",
    )
}

afterEvaluate {
    fun registerDefaultFlutterApkAliasTask(
        taskName: String,
        sourceApkName: String,
        targetApkName: String,
    ) = tasks.register(taskName) {
        doLast {
            val flutterApkDir = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile
            val sourceApk = flutterApkDir.resolve(sourceApkName)
            val targetApk = flutterApkDir.resolve(targetApkName)

            if (sourceApk.isFile) {
                sourceApk.copyTo(targetApk, overwrite = true)
                logger.lifecycle(
                    "Copied ${sourceApk.name} to ${targetApk.name} for default flutter build compatibility.",
                )
            }
        }
    }

    val ensureDefaultDebugApk = registerDefaultFlutterApkAliasTask(
        taskName = "ensureDefaultDebugApk",
        sourceApkName = "app-dev-debug.apk",
        targetApkName = "app-debug.apk",
    )
    val ensureDefaultReleaseApk = registerDefaultFlutterApkAliasTask(
        taskName = "ensureDefaultReleaseApk",
        sourceApkName = "app-dev-release.apk",
        targetApkName = "app-release.apk",
    )

    tasks.matching { it.name == "assembleDebug" }.configureEach {
        finalizedBy(ensureDefaultDebugApk)
    }

    tasks.matching { it.name == "assembleRelease" }.configureEach {
        finalizedBy(ensureDefaultReleaseApk)
    }
}
