# Maintainer Guide

Everything you need to look after **react-native-keys-next**: handling issues, testing fixes,
committing, pushing, and publishing to npm. Commands are meant to be pasted into a terminal.

`MAINTAINING.md` (repo root) is the short policy version. This guide is the step-by-step one.

---

## 1. Where everything lives

| What | Where |
| --- | --- |
| Code (your checkout) | `~/Projects/react-native-keys-next` |
| GitHub repo | https://github.com/the-mysterious-kid/react-native-keys-next |
| npm package | https://www.npmjs.com/package/react-native-keys-next |
| Original project (upstream) | https://github.com/numandev1/react-native-keys |
| Compatibility test scripts | `~/Projects/rnkeys-matrix/harness` |
| RN 0.87 test app (POC) | `~/Projects/RNKeysPOC` |

Git setup in the checkout:

| Name | Points to | Use |
| --- | --- | --- |
| `main` (branch) | `origin/main` | Your work. Releases are cut from here. |
| `upstream-main` (branch) | `upstream/main` | Read-only copy of the original project. |
| `origin` (remote) | the-mysterious-kid/react-native-keys-next | Push here. |
| `upstream` (remote) | numandev1/react-native-keys | Fetch only. Never push. |

---

## 2. One-time setup

### Git identity (personal email only)

This repo is set to commit as `Prithin <prithin123@gmail.com>`. Check it whenever you clone
again or work on a new machine:

```bash
git -C ~/Projects/react-native-keys-next config user.email
```

It must print `prithin123@gmail.com`. If it doesn't:

```bash
git -C ~/Projects/react-native-keys-next config user.name "Prithin"
```

```bash
git -C ~/Projects/react-native-keys-next config user.email "prithin123@gmail.com"
```

Never set your work email in this repo. The email in a commit is public forever once pushed.

### npm

```bash
npm whoami
```

It should print `prithin_babu`. If not, run `npm login` and finish in the browser.
Publishing needs your passkey every time (2FA), which is why you publish from a terminal yourself.

### GitHub settings (once, in the browser)

Repository → **Settings**:
- **General → Features → Discussions**: turn on (the issue form sends questions there).
- **Security → Private vulnerability reporting**: enable (SECURITY.md links to it).
- **Branches → Add rule for `main`**: optional, but blocks force-pushes and deletion.

Repository → **Issues → Labels**, create:
`needs-triage`, `needs-info`, `question`, `bug`, `enhancement`, `upstream`, `help wanted`,
`good first issue`, `duplicate`, `wontfix`, `ios`, `android`, `expo`.

### Node

The build tool (bob) needs Node 22.12+ to run without warnings. On Node 22.11 (what you have now),
prefix `npm pack` / `npm publish` with `NODE_OPTIONS=--experimental-require-module`, as shown
in every command below. Upgrading Node removes that need.

---

## 3. Handling a new issue

Every new bug arrives with the `bug` + `needs-triage` labels and the form fields filled in.

### Step 1: Is the information there?

You need: package version, RN version, platform, architecture, Debug/Release, and repro steps.
If something is missing, reply with this and add the **`needs-info`** label:

> Thanks for the report! To look into this I need a few more details:
> - output of `npm ls react-native-keys-next`
> - React Native version and whether the New Architecture is on
> - the full error from the build log or device log
> - ideally a minimal repo that reproduces it
>
> I've marked this as waiting for info. It closes automatically after 3 weeks without a reply.

When they reply, remove `needs-info`. (The bot only ever closes `needs-info` issues.)

### Step 2: Is it a setup problem? (most issues are)

Match the symptom against this table first:

| Symptom | Cause | Answer |
| --- | --- | --- |
| `Keys.secureFor('X')` returns `""` | Keys file not found at build time, key not under `secure`, wrong `ENVFILE` | Check the file path is relative to the project root and the key is in the `secure` block. Clean build. |
| `""` only on iOS | Xcode pre-action not set on the scheme being built, or "Provide build settings from" empty | README → iOS setup. Clean build folder. |
| `""` on one platform after building both | iOS and Android built at the same time from one checkout | Build one at a time; clean build the broken one. |
| `The package 'react-native-keys-next' doesn't seem to be linked` | Pods not installed, stale build, or Expo Go | `pod install`, clean build, full rebuild (not a Metro reload). Expo: prebuild + dev build. |
| `env: node: No such file or directory` in Xcode | Node installed via nvm/fnm, not on Xcode's PATH | README → "Using node with nvm, fnm or notion". |
| Public keys `undefined` in Android **release** only | Proguard renamed `BuildConfig` | README → "Problems with Proguard". |
| `2 files found with path '**/libcrypto.so'` | Another library also bundles OpenSSL | README → `pickFirst` snippet. |
| Expo: works locally, broken on EAS | Keys file not uploaded (gitignored) or `ENVFILE` not set in `eas.json` | Use EAS secrets / env, and set `ENVFILE` in the build profile. |
| Build error mentioning `fmt`, `consteval`, deployment target | Xcode / React Native issue, not this package | Point to the RN issue; mark `upstream`. |

If it matches, answer with the fix and a link to the README section, label `question`, and close.
**If the same question comes up twice, add it to the README Troubleshooting section.**

### Step 3: Reproduce it

Make a clean app on **their** React Native version (outside the repo folder):

```bash
cd ~/Projects && npx @react-native-community/cli init Repro --version 0.87.1
```

```bash
cd ~/Projects/Repro && npm install react-native-keys-next
```

Add the keys setup from the README (keys JSON, Xcode pre-action, `app/build.gradle` lines), use
the keys in `App.tsx` (see `~/Projects/RNKeysPOC/App.tsx` for a ready-made screen), then build
**Release**, because secure keys behave differently in debug:

```bash
cd ~/Projects/Repro/ios && pod install
```

```bash
cd ~/Projects/Repro && npx react-native run-ios --mode Release
```

```bash
cd ~/Projects/Repro && npx react-native run-android --mode release
```

Remember: one platform at a time.

- Can't reproduce → ask for a minimal repo, add `needs-info`.
- Reproduced in React Native itself (also happens without this package) → label `upstream`.
- Reproduced → label `bug` (and `ios` / `android`), remove `needs-triage`, go to section 4.

### Step 4: Close the loop

When the fix is published, comment:

> Fixed in 1.0.1: `npm install react-native-keys-next@latest`. Thanks for reporting!

and close the issue. If a PR fixes it, write `Fixes #12` in the PR description and GitHub closes
it on merge.

### Security reports

If someone posts a vulnerability publicly: edit/hide the details, ask them to use
**Security → Report a vulnerability**, then fix it in a patch release before discussing it publicly.

---

## 4. Fixing a bug

### Where the code is

| Area | File |
| --- | --- |
| JS API (`Keys.X`, `Keys.secureFor`) | `src/index.ts` |
| iOS native module / JSI install | `ios/Keys.mm` |
| Android JNI (secureFor, publicKeys) | `android/cpp-adapter.cpp` |
| Android Gradle / CMake | `android/build.gradle`, `android/CMakeLists.txt` |
| Key encryption at build time | `keysIOS.js`, `keysAndroid.js`, `src/util/` |
| Decryption (shared C++) | `cpp/` |
| Expo config plugin | `plugin/src/` |
| iOS pod | `react-native-keys-next.podspec` |

Things that broke on React Native upgrades before: the JSI install hooks in `ios/Keys.mm`
(`installJSIBindingsWithRuntime:` / `...callInvoker:`), paths into `node_modules/react-native`
in `android/build.gradle`, and Xcode minimum versions.

### Test your fix in an app before committing

Pack the package exactly as npm would and install the tarball into the repro app:

```bash
cd ~/Projects/react-native-keys-next && NODE_OPTIONS=--experimental-require-module npm pack --pack-destination ~/Projects
```

```bash
cd ~/Projects/Repro && npm install ~/Projects/react-native-keys-next-1.0.0.tgz
```

Then `pod install` and build Release again (section 3). Test at least:
the reporter's RN version, **0.75** (oldest supported) and the **newest** RN.

For a release that changes native code, run the full matrix in `~/Projects/rnkeys-matrix/harness`
(`final-run.sh` reinstalls a tarball into all 15 test apps and builds iOS + Android).

---

## 5. Committing: things to check every time

### Before `git add`

```bash
cd ~/Projects/react-native-keys-next && git status
```

Read the list. **Never commit:**

| File(s) | Why |
| --- | --- |
| `cpp/encrypted_functions.h`, `cpp/password_functions.h`, `android/src/main/java/com/reactnativekeysjsi/PrivateKey.java`, `ios/privateKey.m` | Regenerated with **real key material** whenever an app (e.g. `example/`) builds from this checkout. |
| `.env*`, `keys.*.json` with real values | Secrets. |
| `*.tgz` | `npm pack` output (already gitignored). |
| `yarn.lock` changes you didn't intend | Your local Yarn (3.x) rewrites the lockfile in a different format. |
| `lib/`, `plugin/build/` | Build output, generated on publish. |

If the key files show up as modified, put them back:

```bash
cd ~/Projects/react-native-keys-next && git checkout -- cpp/encrypted_functions.h cpp/password_functions.h android/src/main/java/com/reactnativekeysjsi/PrivateKey.java
```

Add files by name rather than `git add -A`, so nothing slips in:

```bash
cd ~/Projects/react-native-keys-next && git add ios/Keys.mm CHANGELOG.md
```

Then check exactly what's staged:

```bash
cd ~/Projects/react-native-keys-next && git diff --staged
```

### Commit messages

Use a type prefix, then what changed and why:

| Prefix | For | Example |
| --- | --- | --- |
| `fix:` | bug fixes | `fix(android): return "" for missing secure key instead of crashing` |
| `feat:` | new capability / new RN support | `feat: support React Native 0.88` |
| `docs:` | README, guides | `docs: add EAS setup to troubleshooting` |
| `chore:` | releases, tooling | `chore: release 1.0.1` |
| `ci:` | GitHub Actions | `ci: build example app on RN 0.87` |

Mention the issue number when there is one: `fix(ios): decode keys as UTF-8 (#12)`.

```bash
cd ~/Projects/react-native-keys-next && git commit -m "fix(ios): describe the fix (#12)"
```

Also add a line to `CHANGELOG.md` under `## [Unreleased]` in the same commit.

---

## 6. Pushing

```bash
cd ~/Projects/react-native-keys-next && git log --oneline origin/main..main
```

This lists the commits you're about to push. Make sure they're the ones you expect. Then:

```bash
cd ~/Projects/react-native-keys-next && git push origin main --follow-tags
```

`--follow-tags` also pushes release tags (`v1.0.1`) that point at those commits.

Rules:
- **Never `git push --force` on `main`.** Anyone who cloned it breaks. If a pushed commit is wrong,
  make a new commit that fixes or reverts it (`git revert <hash>`).
- Never push to `upstream` (you can't, but don't try).
- If the push is rejected ("fetch first"), someone merged a PR on GitHub. Run
  `git pull --rebase origin main`, check `git status`, then push again.
- If you edited a file on GitHub's website, pull before working locally.

---

## 7. Publishing a new version to npm

Decide the version first:

| What changed | Version | Command |
| --- | --- | --- |
| Bug fix | patch: 1.0.0 → 1.0.1 | `npm version patch` |
| New RN version supported, new feature | minor: 1.0.1 → 1.1.0 | `npm version minor` |
| Users must change setup, or minimum RN raised | major: 1.1.0 → 2.0.0 | `npm version major` |

Use the manual steps below, not `npm run release`. That script is release-it, set up by the
original project: it regenerates `CHANGELOG.md` in a different format and needs a GitHub token.

### Release steps

**1. Start clean and up to date**

```bash
cd ~/Projects/react-native-keys-next && git checkout main && git pull && git status
```

`git status` must say "nothing to commit, working tree clean". (Uncommitted changes would be
published, including the key files from section 5.)

**2. Update the changelog**

In `CHANGELOG.md`, rename `## [Unreleased]` to `## [1.0.1] - YYYY-MM-DD`, add a fresh empty
`## [Unreleased]` above it, and update the compare links at the bottom. Commit it:

```bash
cd ~/Projects/react-native-keys-next && git commit -am "docs: changelog for 1.0.1"
```

**3. Bump the version** (creates the commit `1.0.1` and the tag `v1.0.1`)

```bash
cd ~/Projects/react-native-keys-next && npm version patch -m "chore: release %s"
```

**4. Check what will be uploaded**

```bash
cd ~/Projects/react-native-keys-next && NODE_OPTIONS=--experimental-require-module npm pack --dry-run
```

Look for: the right version, around 230 files, `plugin/build/` present, no `example/`, no `.tgz`.

**5. Publish**

```bash
cd ~/Projects/react-native-keys-next && NODE_OPTIONS=--experimental-require-module npm publish --access public
```

npm prints `Authenticate your account at https://www.npmjs.com/auth/cli/...` and `Press ENTER`.
Press Enter, approve with your passkey in the browser, and wait for
`+ react-native-keys-next@1.0.1`.

**6. Push the release commit and tag**

```bash
cd ~/Projects/react-native-keys-next && git push origin main --follow-tags
```

**7. GitHub release**

Open https://github.com/the-mysterious-kid/react-native-keys-next/releases/new, pick the tag
(`v1.0.1`), title it `v1.0.1`, paste that version's CHANGELOG section, publish.

**8. Verify**

```bash
npm view react-native-keys-next dist-tags
```

`latest` should show the new version. The npmjs.com page can take up to an hour to update,
even though installs work immediately. Then reply on the issues that this release fixes.

### Pre-releases (to let people test before a stable release)

```bash
cd ~/Projects/react-native-keys-next && npm version prerelease --preid beta -m "chore: release %s"
```

```bash
cd ~/Projects/react-native-keys-next && NODE_OPTIONS=--experimental-require-module npm publish --access public --tag next
```

Always use `--tag next` for betas. Without it the beta becomes `latest` and everyone gets it.
Testers install it with `npm install react-native-keys-next@next`.

### If a release is broken

Don't unpublish. Fix it and release a patch, then warn people off the bad version:

```bash
npm deprecate react-native-keys-next@1.0.1 "Broken on Android release builds, use 1.0.2"
```

If `latest` points to the wrong version:

```bash
npm dist-tag add react-native-keys-next@1.0.0 latest
```

Both commands ask for your passkey like `publish` does.

### npm errors you may see

| Error | Meaning / fix |
| --- | --- |
| `E403 ... two-factor authentication` / `EOTP` | Run the command in a normal terminal so you can press Enter and approve in the browser. It can't run in the background. |
| `E403 You cannot publish over the previously published versions` | That version already exists. Bump the version again. |
| `ENEEDAUTH` / `npm whoami` fails | `npm login`. |
| `Error [ERR_REQUIRE_ESM]` during prepare | Missing `NODE_OPTIONS=--experimental-require-module` (or upgrade Node to 22.12+). |
| npm page still shows the old version | Website cache. Trust `npm view react-native-keys-next dist-tags`. |

---

## 8. Keeping up with React Native

React Native ships a new minor version about every two months.

1. When a release candidate is announced (React Native blog / GitHub releases), create a repro app
   with `--version 0.x.0-rc.0`, install the package, and build iOS and Android Release.
2. If it breaks, fix it and publish a `-beta` with `--tag next` so people can try it on the RC.
3. When the stable RN version is out and passes, add it to the **Tested** table in the README and
   publish a **minor** version, even if no code changed. That's how users know it's supported.

Every few months:
- `git fetch upstream` and look at `git log upstream-main..upstream/main` for fixes worth porting.
- Check for OpenSSL security releases and update Android's prebuilt OpenSSL and the iOS
  `OpenSSL-Universal` pod together.
- Run the full matrix before minor releases.

---

## 9. Quick reference

```bash
cd ~/Projects/react-native-keys-next && git status && git log --oneline -5
```

```bash
npm view react-native-keys-next dist-tags
```

```bash
cd ~/Projects/react-native-keys-next && NODE_OPTIONS=--experimental-require-module npm pack --dry-run
```

Release in one line each (after the changelog is committed):

```bash
cd ~/Projects/react-native-keys-next && npm version patch -m "chore: release %s"
```

```bash
cd ~/Projects/react-native-keys-next && NODE_OPTIONS=--experimental-require-module npm publish --access public
```

```bash
cd ~/Projects/react-native-keys-next && git push origin main --follow-tags
```

Golden rules:
1. Commit as `prithin123@gmail.com`, never the work email.
2. `git status` before every commit and every publish. Key files and secrets never get committed.
3. Build one platform at a time.
4. Never force-push `main`, never unpublish. Fix forward and deprecate.
5. Betas go to `--tag next`, stable to `latest`.
6. Every release gets a CHANGELOG entry, a tag, and a GitHub release.
