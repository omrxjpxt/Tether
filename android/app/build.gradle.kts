import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Locate key.properties in android/ (rootProject) or android/app/ (project)
val keystorePropertiesFile = rootProject.file("key.properties").takeIf { it.exists() }
    ?: project.file("key.properties").takeIf { it.exists() }

val keystoreProperties = Properties()
if (keystorePropertiesFile != null && keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

// Resolve keystore file path supporting ~, absolute, and relative paths
fun resolveKeystoreFile(rawPath: String?): File? {
    if (rawPath.isNullOrBlank()) return null
    val trimmed = rawPath.trim()
    return when {
        trimmed.startsWith("~/") -> File(System.getProperty("user.home"), trimmed.removePrefix("~/"))
        trimmed.startsWith("~\\") -> File(System.getProperty("user.home"), trimmed.removePrefix("~\\"))
        File(trimmed).isAbsolute -> File(trimmed)
        rootProject.file(trimmed).exists() -> rootProject.file(trimmed)
        else -> project.file(trimmed)
    }
}

val configuredStoreFile = resolveKeystoreFile(keystoreProperties.getProperty("storeFile"))
val isSigningConfigured = keystorePropertiesFile != null &&
    !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyPassword").isNullOrBlank() &&
    !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
    configuredStoreFile != null &&
    configuredStoreFile.exists()

if (keystorePropertiesFile != null && !isSigningConfigured) {
    logger.warn("WARNING: key.properties found at ${keystorePropertiesFile.absolutePath}, but keystore file or credentials are invalid. Falling back to debug signing.")
}

android {
    namespace = "com.example.tether"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // PRODUCTION APPLICATION ID:
        // Registered production Application ID for Google Play.
        applicationId = "app.tether.habits"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (isSigningConfigured) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = configuredStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (isSigningConfigured) {
                signingConfigs.getByName("release")
            } else {
                // Fallback to debug keystore for local non-signing builds
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

