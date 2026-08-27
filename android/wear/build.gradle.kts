plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.example.cronos.wear"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.cronos"
        minSdk = 30
        targetSdk = 36
        versionCode = 22
        versionName = "0.13.0"
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures { compose = true }
}

kotlin { compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 } }

dependencies {
    implementation("androidx.activity:activity-compose:1.12.2")
    implementation("androidx.wear.compose:compose-material3:1.5.6")
    implementation("androidx.wear.compose:compose-foundation:1.5.6")
    implementation("com.google.android.gms:play-services-wearable:19.0.0")
}
