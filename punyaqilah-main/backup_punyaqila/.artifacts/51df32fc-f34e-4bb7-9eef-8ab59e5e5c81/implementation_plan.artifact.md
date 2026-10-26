# Upgrade Gradle to 9.1.0 for Java 25 Compatibility

The project is using Java 25.0.2, which requires Gradle 9.1.0 or newer. Currently, the project is configured with Gradle 8.14. This plan upgrades the Gradle version and adjusts related configurations if necessary.

## User Review Required

> [!IMPORTANT]
> Upgrading Gradle to 9.1.0 might require a corresponding upgrade of the Android Gradle Plugin (AGP). I will start by upgrading Gradle and see if the current AGP (8.11.1) is compatible. If not, I will propose an AGP upgrade.

## Proposed Changes

### Gradle Configuration

#### [MODIFY] [gradle-wrapper.properties](file:///D:/punyaqila/android/gradle/wrapper/gradle-wrapper.properties)
- Update `distributionUrl` to `https\://services.gradle.org/distributions/gradle-9.1-all.zip`.

## Verification Plan

### Automated Tests
- Run `./gradlew help` in the `android` directory to verify Gradle can initialize with Java 25.
- Attempt a build using `flutter build apk --debug`.

### Manual Verification
- Verify that the IDE no longer reports the Java/Gradle incompatibility.
