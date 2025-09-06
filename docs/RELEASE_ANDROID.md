# Android Release Guide

This repo includes a GitHub Actions workflow for Android release builds.

## Prerequisites

- A signing keystore (.jks or .keystore)
- Keystore alias, keystore password, and key password

## Configure GitHub Secrets

Add the following repository secrets in GitHub → Settings → Secrets and variables → Actions:

- ANDROID_KEYSTORE_BASE64: Base64 of your keystore file
- ANDROID_KEYSTORE_PASSWORD: The keystore password
- ANDROID_KEY_ALIAS: The key alias
- ANDROID_KEY_PASSWORD: The key password

Tip (Windows, PowerShell) to generate base64:

```
[Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\\path\\to\\release.keystore')) > keystore.b64
```

Copy the contents of keystore.b64 to ANDROID_KEYSTORE_BASE64.

## Trigger a Release Build

- Push a tag like `v1.0.0` to the default branch or dispatch the workflow manually.

Artifacts produced:

- Split-per-ABI APKs: `build/app/outputs/flutter-apk/*.apk`
- App Bundle (AAB): `build/app/outputs/bundle/release/*.aab`
- Obfuscation symbols: `build/symbols`

## Local sanity check (optional)

You can do a quick local build before tagging:

```
flutter pub get
flutter build apk --debug
```

For a local release build without signing (will use debug signing):

```
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
```

## Notes

- The Gradle config reads signing details from environment variables if present; otherwise it falls back to debug signing for local builds.
- ProGuard/R8 minification and resource shrinking are enabled for release.
