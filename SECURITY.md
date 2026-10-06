# Security Policy

## Supported versions

| Version | Supported |
| --- | --- |
| 1.x (latest minor) | ✅ |
| 1.0.0-beta.x | ❌ upgrade to 1.x |
| `react-native-keys` ≤ 0.7.x (upstream) | ❌ not maintained here |

## Reporting a vulnerability

**Please do not open a public issue.** Report it privately through
[GitHub Security Advisories](https://github.com/the-mysterious-kid/react-native-keys-next/security/advisories/new).

Include the package and React Native versions, the platform, and steps or a proof of concept.
Never include real secrets.

You can expect an acknowledgement within 7 days. Confirmed issues are fixed in a patch release
and disclosed in a GitHub advisory once the fix is published.

## Scope

In scope:
- Secure keys (`Keys.secureFor`) recoverable by **static analysis** of a release APK/IPA
  (decompiling, string dumps, reading the bundle or native binaries).
- Key material leaking into build output, logs or the published npm package.
- Memory-safety bugs in the native code (`cpp/`, `ios/`, `android/`).

Out of scope (known limitations, see the README):
- Reading values at runtime on a rooted/jailbroken device with hooking tools (Frida, etc.).
- Public keys (`Keys.X`), which are stored in plain text by design.
- Vulnerabilities in your own app or CI that expose your keys JSON files.
