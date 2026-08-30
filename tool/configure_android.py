from pathlib import Path
import re


def configure_manifest() -> None:
    manifest = Path("android/app/src/main/AndroidManifest.xml")
    text = manifest.read_text(encoding="utf-8")

    permissions = """
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
"""
    if "android.permission.INTERNET" not in text:
        text = text.replace(">", ">" + permissions, 1)
    else:
        for permission in (
            "android.permission.USE_BIOMETRIC",
            "android.permission.POST_NOTIFICATIONS",
            "android.permission.RECEIVE_BOOT_COMPLETED",
        ):
            if permission not in text:
                text = text.replace(
                    ">",
                    f'>\n    <uses-permission android:name="{permission}" />',
                    1,
                )

    if "android:allowBackup=" not in text:
        text = text.replace(
            "<application",
            '<application\n        android:allowBackup="true"',
            1,
        )

    receivers = """
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
"""
    if "ScheduledNotificationReceiver" not in text:
        text = text.replace("</application>", receivers + "\n    </application>")

    manifest.write_text(text, encoding="utf-8")


def configure_activity() -> None:
    activity = Path("android/app/src/main/kotlin/com/finora/finora/MainActivity.kt")
    activity.parent.mkdir(parents=True, exist_ok=True)
    activity.write_text(
        """package com.finora.finora

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
""",
        encoding="utf-8",
    )


def configure_styles() -> None:
    for style_path in (
        Path("android/app/src/main/res/values/styles.xml"),
        Path("android/app/src/main/res/values-night/styles.xml"),
    ):
        if not style_path.exists():
            continue
        style = style_path.read_text(encoding="utf-8")
        style = re.sub(
            r'(<style name="(?:LaunchTheme|NormalTheme)" parent=")[^"]+("[^>]*>)',
            r"\1Theme.AppCompat.DayNight.NoActionBar\2",
            style,
        )
        style_path.write_text(style, encoding="utf-8")


def configure_gradle() -> None:
    gradle = Path("android/app/build.gradle.kts")
    app = gradle.read_text(encoding="utf-8")

    imports = """import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

"""
    if "val keystoreProperties = Properties()" not in app:
        app = imports + app

    app = re.sub(
        r"compileSdk\s*=\s*flutter\.compileSdkVersion",
        "compileSdk = 37",
        app,
    )
    app = re.sub(
        r"minSdk\s*=\s*flutter\.minSdkVersion",
        "minSdk = 24",
        app,
    )

    if "isCoreLibraryDesugaringEnabled" not in app:
        app = app.replace(
            "compileOptions {",
            "compileOptions {\n        isCoreLibraryDesugaringEnabled = true",
            1,
        )

    app = re.sub(
        r"sourceCompatibility\s*=\s*JavaVersion\.VERSION_\d+",
        "sourceCompatibility = JavaVersion.VERSION_17",
        app,
    )
    app = re.sub(
        r"targetCompatibility\s*=\s*JavaVersion\.VERSION_\d+",
        "targetCompatibility = JavaVersion.VERSION_17",
        app,
    )
    app = re.sub(
        r"jvmTarget\s*=\s*JavaVersion\.VERSION_\d+\.toString\(\)",
        "jvmTarget = JavaVersion.VERSION_17.toString()",
        app,
    )

    if "multiDexEnabled = true" not in app:
        app = app.replace(
            "defaultConfig {",
            "defaultConfig {\n        multiDexEnabled = true",
            1,
        )

    signing_config = """    signingConfigs {
        create("finoraRelease") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

"""
    if 'create("finoraRelease")' not in app:
        app = app.replace("    buildTypes {", signing_config + "    buildTypes {", 1)

    app = app.replace(
        'signingConfig = signingConfigs.getByName("debug")',
        'signingConfig = signingConfigs.getByName("finoraRelease")',
    )

    if "com.android.tools:desugar_jdk_libs" not in app:
        app += """

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.appcompat:appcompat:1.7.1")
}
"""

    gradle.write_text(app, encoding="utf-8")


def configure_android_plugin() -> None:
    settings = Path("android/settings.gradle.kts")
    if not settings.exists():
        return
    cfg = settings.read_text(encoding="utf-8")
    cfg = re.sub(
        r'id\("com\.android\.application"\) version "[^"]+" apply false',
        'id("com.android.application") version "8.11.1" apply false',
        cfg,
    )
    settings.write_text(cfg, encoding="utf-8")


def main() -> None:
    configure_activity()
    configure_manifest()
    configure_styles()
    configure_gradle()
    configure_android_plugin()
    print("Android configurado para o Finora.")


if __name__ == "__main__":
    main()
