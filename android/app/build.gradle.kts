import java.io.FileInputStream
import java.security.KeyStore
import java.security.MessageDigest
import java.security.cert.Certificate
import java.security.cert.CertificateFactory

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

fun resolveKeystoreCandidates(rawPath: String): List<File> {
    val normalizedPath = rawPath.replace("\\", "/")
    val isAbsolutePath =
        normalizedPath.contains(":") ||
            (normalizedPath.startsWith("/") && !normalizedPath.startsWith("./"))

    val candidates = linkedSetOf<File>()
    if (isAbsolutePath) {
        candidates += file(normalizedPath)
    } else {
        candidates += rootProject.file(normalizedPath)
        if (normalizedPath.startsWith("android/")) {
            candidates += rootProject.file(normalizedPath.removePrefix("android/"))
        } else {
            candidates += file(normalizedPath)
            candidates += rootProject.file("app/$normalizedPath")
        }
    }

    return candidates.toList()
}

fun sha1Of(certificate: Certificate): String =
    MessageDigest.getInstance("SHA-1")
        .digest(certificate.encoded)
        .joinToString(":") { byte -> "%02X".format(byte) }

data class ReleaseSigningStatus(
    val keystoreCandidates: List<File>,
    val keystoreFile: File?,
    val expectedSha1: String?,
    val actualSha1: String?,
    val isReady: Boolean,
    val message: String,
)

fun loadExpectedUploadSha1(): String? {
    val expectedCertificateFile = rootProject.file("upload_certificate.pem")
    if (!expectedCertificateFile.isFile) {
        return null
    }

    FileInputStream(expectedCertificateFile).use { input ->
        val certificate = CertificateFactory.getInstance("X.509").generateCertificate(input)
        return sha1Of(certificate)
    }
}

fun buildReleaseSigningStatus(): ReleaseSigningStatus {
    val keystoreCandidates =
        configuredKeystorePath?.let(::resolveKeystoreCandidates).orEmpty()
    val keystoreFile = keystoreCandidates.firstOrNull { it.isFile }
    val expectedSha1 = loadExpectedUploadSha1()

    val missingConfig = buildList {
        if (configuredKeystorePath == null) add("MOVI_KEYSTORE")
        if (configuredStorePassword == null) add("MOVI_STORE_PASSWORD")
        if (configuredAlias == null) add("MOVI_ALIAS")
        if (configuredKeyPassword == null) add("MOVI_KEY_PASSWORD")
    }

    if (missingConfig.isNotEmpty()) {
        return ReleaseSigningStatus(
            keystoreCandidates = keystoreCandidates,
            keystoreFile = keystoreFile,
            expectedSha1 = expectedSha1,
            actualSha1 = null,
            isReady = false,
            message = "Missing release signing config: ${missingConfig.joinToString(", ")}",
        )
    }

    if (keystoreFile == null) {
        val searchedPaths =
            keystoreCandidates
                .ifEmpty { listOf(File(configuredKeystorePath!!)) }
                .joinToString(", ") { it.absolutePath }
        return ReleaseSigningStatus(
            keystoreCandidates = keystoreCandidates,
            keystoreFile = null,
            expectedSha1 = expectedSha1,
            actualSha1 = null,
            isReady = false,
            message = "Release keystore not found. Searched: $searchedPaths",
        )
    }

    if (expectedSha1 == null) {
        return ReleaseSigningStatus(
            keystoreCandidates = keystoreCandidates,
            keystoreFile = keystoreFile,
            expectedSha1 = null,
            actualSha1 = null,
            isReady = false,
            message = "Expected Play upload certificate is missing: ${rootProject.file("upload_certificate.pem").absolutePath}",
        )
    }

    return try {
        val keyStore = KeyStore.getInstance(KeyStore.getDefaultType())
        FileInputStream(keystoreFile).use { input ->
            keyStore.load(input, configuredStorePassword!!.toCharArray())
        }

        val certificate =
            keyStore.getCertificate(configuredAlias)
                ?: return ReleaseSigningStatus(
                    keystoreCandidates = keystoreCandidates,
                    keystoreFile = keystoreFile,
                    expectedSha1 = expectedSha1,
                    actualSha1 = null,
                    isReady = false,
                    message = "Alias '$configuredAlias' not found in release keystore ${keystoreFile.absolutePath}",
                )

        val actualSha1 = sha1Of(certificate)

        keyStore.getKey(configuredAlias, configuredKeyPassword!!.toCharArray())
            ?: return ReleaseSigningStatus(
                keystoreCandidates = keystoreCandidates,
                keystoreFile = keystoreFile,
                expectedSha1 = expectedSha1,
                actualSha1 = actualSha1,
                isReady = false,
                message = "Private key for alias '$configuredAlias' is not accessible in ${keystoreFile.absolutePath}",
            )

        if (actualSha1 != expectedSha1) {
            ReleaseSigningStatus(
                keystoreCandidates = keystoreCandidates,
                keystoreFile = keystoreFile,
                expectedSha1 = expectedSha1,
                actualSha1 = actualSha1,
                isReady = false,
                message =
                    "Release keystore fingerprint mismatch. Expected SHA1: $expectedSha1, actual SHA1: $actualSha1, file: ${keystoreFile.absolutePath}",
            )
        } else {
            ReleaseSigningStatus(
                keystoreCandidates = keystoreCandidates,
                keystoreFile = keystoreFile,
                expectedSha1 = expectedSha1,
                actualSha1 = actualSha1,
                isReady = true,
                message =
                    "Release signing ready for prod with SHA1 $actualSha1 using ${keystoreFile.absolutePath}",
            )
        }
    } catch (error: Exception) {
        ReleaseSigningStatus(
            keystoreCandidates = keystoreCandidates,
            keystoreFile = keystoreFile,
            expectedSha1 = expectedSha1,
            actualSha1 = null,
            isReady = false,
            message =
                "Release keystore validation failed for ${keystoreFile.absolutePath}: ${error::class.simpleName}: ${error.message}",
        )
    }
}

val releaseSigningStatus = buildReleaseSigningStatus()
val releaseKeystoreFile = releaseSigningStatus.keystoreFile
val hasReleaseSigning = releaseSigningStatus.isReady

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
        "Movi prodRelease signing unavailable. " +
            "devRelease/stageRelease may still use debug signing, but Play release builds must stop. " +
            releaseSigningStatus.message,
    )
} else {
    logger.lifecycle(releaseSigningStatus.message)
}

afterEvaluate {
    fun requiresProdReleaseSigning(taskName: String): Boolean {
        val normalizedName = taskName.lowercase()
        if (normalizedName == "assemblerelease" || normalizedName == "bundlerelease") {
            return true
        }

        return normalizedName.contains("prodrelease") &&
            (
                normalizedName.startsWith("assemble") ||
                    normalizedName.startsWith("bundle") ||
                    normalizedName.startsWith("package") ||
                    normalizedName.startsWith("sign") ||
                    normalizedName.startsWith("validate")
            )
    }

    gradle.taskGraph.whenReady {
        val needsProdReleaseSigning =
            allTasks.any { task -> requiresProdReleaseSigning(task.name) }
        if (needsProdReleaseSigning && !hasReleaseSigning) {
            throw GradleException(
                "Cannot build Play release without a validated prod signing config. ${releaseSigningStatus.message}",
            )
        }
    }

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

    fun registerDefaultFlutterAabAliasTask(
        taskName: String,
        sourceAabRelativePath: String,
        targetAabRelativePath: String,
    ) = tasks.register(taskName) {
        doLast {
            val outputsDir = layout.buildDirectory.dir("outputs").get().asFile
            val sourceAab = outputsDir.resolve(sourceAabRelativePath)
            val targetAab = outputsDir.resolve(targetAabRelativePath)

            if (sourceAab.isFile) {
                targetAab.parentFile.mkdirs()
                sourceAab.copyTo(targetAab, overwrite = true)
                logger.lifecycle(
                    "Copied ${sourceAab.name} to ${targetAab.name} for default flutter build compatibility.",
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
        sourceApkName = "app-prod-release.apk",
        targetApkName = "app-release.apk",
    )

    val ensureDefaultReleaseAab = registerDefaultFlutterAabAliasTask(
        taskName = "ensureDefaultReleaseAab",
        sourceAabRelativePath = "bundle/prodRelease/app-prod-release.aab",
        targetAabRelativePath = "bundle/release/app-release.aab",
    )

    tasks.matching { it.name == "assembleDebug" }.configureEach {
        finalizedBy(ensureDefaultDebugApk)
    }

    tasks.matching { it.name == "assembleRelease" }.configureEach {
        finalizedBy(ensureDefaultReleaseApk)
    }

    tasks.matching { it.name == "bundleRelease" }.configureEach {
        finalizedBy(ensureDefaultReleaseAab)
    }
}
