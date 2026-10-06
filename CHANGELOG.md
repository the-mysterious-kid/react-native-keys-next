# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-10-06

First stable release. Same code as 1.0.0-beta.1, which passed the full compatibility matrix
(React Native 0.75.5 → 0.87.1, release builds on iOS and Android, secure and public keys verified at runtime).

### Added
- Issue forms, `SECURITY.md`, this changelog, `MAINTAINING.md` and `docs/MAINTAINER_GUIDE.md`.
- README troubleshooting entries for empty secure values and the native-module linking error.

### Changed
- The stale bot only closes issues labelled `needs-info`.

## [1.0.0-beta.1] - 2026-10-06

First release of the fork of [react-native-keys](https://github.com/numandev1/react-native-keys) 0.7.13.

### Added
- React Native 0.75 – 0.87 support, including bridgeless New Architecture (RN 0.82+).
- iOS: JSI bindings installed through `RCTTurboModuleWithJSIBindings`, implementing both
  `installJSIBindingsWithRuntime:` (RN 0.75–0.76) and `installJSIBindingsWithRuntime:callInvoker:` (RN 0.77+).
- A clear error when the native bindings are not linked.
- Works under its own name or as the npm alias `react-native-keys@npm:react-native-keys-next`.

### Fixed
- Android: Gradle no longer depends on `node_modules/react-native/android` (removed in RN 0.80).
- Android: `secureFor` no longer leaks a JNI string buffer and local references on each call.
- Android: a `null` `BuildConfig` field no longer crashes `publicKeys`.
- iOS: secure values are decoded as UTF-8 (non-ASCII values were garbled).
- iOS: a missing key returns `""` (as on Android) instead of crashing.
- `secureFor()` without a string argument throws a JS error instead of reading out of bounds.

[Unreleased]: https://github.com/the-mysterious-kid/react-native-keys-next/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/the-mysterious-kid/react-native-keys-next/compare/v1.0.0-beta.1...v1.0.0
[1.0.0-beta.1]: https://github.com/the-mysterious-kid/react-native-keys-next/releases/tag/v1.0.0-beta.1
