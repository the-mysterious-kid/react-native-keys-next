# Maintaining react-native-keys-next

Notes for the maintainer: how issues are handled, how releases are cut, and what to check when
React Native ships a new version.

## Versioning

[Semantic Versioning](https://semver.org/), with `CHANGELOG.md` updated in every release.

| Change | Bump | Example |
| --- | --- | --- |
| Bug fix, no API or setup change | patch | `1.0.0 → 1.0.1` |
| Supports a new React Native version, new option, new feature | minor | `1.0.1 → 1.1.0` |
| Users must change code, Gradle/Xcode setup, or a supported RN version is dropped | major | `1.1.0 → 2.0.0` |

- `latest` always points to a stable version. Pre-releases (`1.1.0-beta.0`, `-rc.0`) go to the
  `next` dist-tag, so `npm install react-native-keys-next` never installs one by accident.
- Raising the minimum React Native version is a **major** change.
- Never unpublish. If a release is broken, publish a fixed patch and `npm deprecate` the bad one.

## Issue triage

Aim to reply to new issues within a few days, even if it's only "thanks, looking into it".

1. **Check the form.** If versions, logs or a reproduction are missing, ask for them and add
   `needs-info`. Issues with that label get closed automatically after 21 days without a reply
   (`.github/workflows/stale-bot.yml`). No other issue is auto-closed.
2. **Is it a setup problem?** Most reports will be. Common ones:
   - Secure value is `""`: the keys file or ENVFILE isn't found at build time, the Xcode
     pre-action didn't run, or iOS and Android were built at the same time from one checkout.
   - "native module not found": `pod install` not run, or a stale build (clean and rebuild).
   - Release-only `undefined` public keys on Android: Proguard renamed `BuildConfig`.
   Answer it, link the README section, label `question`, and close it. If the same question
   comes up twice, add it to the README **Troubleshooting** section.
3. **Reproduce it.** Create a fresh app on the reporter's RN version
   (`npx @react-native-community/cli init Repro --version 0.x.y`), install the package from npm,
   and try their steps on the same platform, architecture and build type (Debug vs Release
   matters).
4. **Label it and decide:**
   - `bug` (reproduced) → fix (see below), or `help wanted` if you won't get to it soon.
   - `upstream` → the bug is in React Native, Xcode or Gradle; link the upstream issue and
     document a workaround.
   - `wontfix` / `duplicate` → close with a one-line reason and a link.
   - `enhancement` → leave open, decide when planning the next minor release.
5. **Security reports** go through private advisories (`SECURITY.md`). If one is opened as a
   public issue, hide the details (edit or delete the comment), ask the reporter to use the
   advisory form, and fix it in a patch release.

Suggested labels: `bug`, `needs-triage`, `needs-info`, `question`, `enhancement`, `upstream`,
`help wanted`, `good first issue`, `duplicate`, `wontfix`, `ios`, `android`, `expo`.

## Fixing a bug

1. Branch from `main`, write the fix, and update the `[Unreleased]` section of `CHANGELOG.md`.
2. Test against the reported RN version on the affected platform, plus the oldest (0.75) and
   newest supported RN versions. Use release builds; secure keys only matter in release.
3. Comment on the issue with the fixed version once it's published, then close it.

## Releasing

Run from a clean `main` with Node ≥ 22.12 (or prefix commands with
`NODE_OPTIONS=--experimental-require-module` on older Node 22).

```sh
# 1. Version and changelog
#    Edit CHANGELOG.md: move [Unreleased] entries under the new version and date.
npm version 1.0.1 --no-git-tag-version
git commit -am "chore: release 1.0.1"
git tag v1.0.1

# 2. Check what will be published
npm pack --dry-run          # no example/, no *.tgz, plugin/build present

# 3. Publish (npm asks you to approve with your passkey)
npm publish --access public                 # stable → latest
npm publish --access public --tag next      # pre-release → next

# 4. Push
git push origin main --follow-tags
```

Then create a GitHub release for the tag, pasting the changelog section as the notes.

After publishing, install the new version into a fresh app and confirm that `Keys.secureFor`
returns the right value in a release build.

## New React Native versions

React Native ships a minor version about every two months, and each one has release candidates first.

1. When an RC is out (`npx @react-native-community/cli init Repro --version 0.x.0-rc.0`),
   build iOS and Android in Release with the New Architecture and check secure and public keys.
2. Things that have broken this package before: JSI binding hooks on iOS (the
   `RCTTurboModuleWithJSIBindings` selectors), removed folders under `node_modules/react-native`
   (Gradle paths), and Xcode/SDK minimums. Read the RN changelog's "Breaking" and "iOS/Android
   native" sections.
3. Once the stable RN version passes, add it to the **Tested** table in the README and release a
   minor version, even if no code changed. That tells users it's supported.
4. Old Architecture: still testable where RN allows it (≤ 0.81). Keep it working, but New
   Architecture failures take priority.

The full compatibility matrix (15 RN versions × iOS + Android) was run with the scripts in
`~/Projects/rnkeys-matrix/harness`. Run it before every minor release.

## Dependencies

- **OpenSSL**: Android ships prebuilt OpenSSL in `android/`; iOS uses the `OpenSSL-Universal`
  pod. Check for OpenSSL security releases each quarter and update both together (patch release).
- **Upstream**: `git fetch upstream` now and then to see whether
  [numandev1/react-native-keys](https://github.com/numandev1/react-native-keys) has fixes worth
  porting. Credit the original author in the changelog when you port one.

## Pull requests

- Ask for a test plan (RN version, platform, release build) on every native change.
- Squash-merge with a conventional-commit title (`fix:`, `feat:`, `docs:`, `chore:`).
- Add the change to `CHANGELOG.md` `[Unreleased]` if the PR didn't.
