# Releasing a New Version

How to cut and ship a new UNIUN release for **iOS**, **Android**, and **Windows**. Follow the
steps in order. Everything user-facing is driven from one place — the `version` line in
[`pubspec.yaml`](../pubspec.yaml).

---

## Overview

1. [Bump the version](#1-bump-the-version-in-pubspecyaml) in `pubspec.yaml`.
2. [Update the changelog](#2-update-the-changelog) in [`CHANGELOG.md`](../CHANGELOG.md).
3. [Make sure signing is set up](#3-signing--keys) (keystore + `key.properties` for Android, certs for iOS).
4. [Build the release artifacts](#4-build-the-release-artifacts) (`.ipa` for iOS, `.aab` for Android, installer `.exe` for Windows).
5. [Upload & tag](#5-upload--tag).

---

## 1. Bump the version in `pubspec.yaml`

The version lives on a single line:

```yaml
version: 1.1.0+2
```

It has two parts:

```
1.1.0      +2
└─ name ─┘ └ build ┘
```

- **Version name** (`1.1.0`) — the human-facing `MAJOR.MINOR.PATCH` shown in stores. Bump it
  according to **Semantic Versioning**:

  | Change type                          | Example              | What moves |
  |--------------------------------------|----------------------|------------|
  | **Bug fix** (patch)                  | `1.2.0+15 → 1.2.1+16` | PATCH      |
  | **New feature** (backwards-compatible) | `1.2.0+15 → 1.3.0+16` | MINOR (PATCH resets to 0) |
  | **Major redesign / breaking change** | `1.2.0+15 → 2.0.0+16` | MAJOR (MINOR + PATCH reset to 0) |

- **Build number** (`+2`) — the integer after the `+`. This becomes Android `versionCode` and
  the iOS build number (`android/app/build.gradle.kts` reads `flutter.versionCode` /
  `flutter.versionName` from this line). **It must strictly increase on every single upload to
  a store**, even for a re-upload of the same version name. Both Google Play and App Store
  Connect reject a build whose number was already used. When in doubt, bump it.

> ⚠️ A version with **no** `+build` suffix (e.g. just `1.1.0`) makes Flutter default the build
> number to `1`. Always include an explicit, increasing build number before a store upload.

---

## 2. Update the changelog

Add a new section at the top of [`CHANGELOG.md`](../CHANGELOG.md), above the previous release.
Follow the existing format (Keep a Changelog): group entries under **Added / Changed / Fixed**.

```markdown
## [1.2.0] — 2026-07-01

### Added
- Short, user-facing description of the new feature.

### Changed
- What behaviour or UI changed.

### Fixed
- The bug, in one line.
```

`1.0.0` was the initial release; every release since is appended here. Keep entries
**user-facing and concise** — this is the same text that feeds store "What's New" notes.

---

## 3. Signing & keys

A release build **must be signed**. Debug builds are signed automatically; release builds are
not. Set this up once per machine and keep the secrets safe.

### Android — upload keystore + `key.properties`

The release `signingConfig` in `android/app/build.gradle.kts` reads four values from a file at
`android/key.properties` (kept out of git — see `android/.gitignore`, which ignores
`key.properties`, `**/*.jks`, and `**/*.keystore`).

**a) Generate the keystore (once, ever).** Pick a location *outside* the repo:

```bash
keytool -genkey -v \
  -keystore ~/uniun-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

You'll be prompted for a store password, a key password, and your name/org. Remember these.

> 🔐 **Back this file up forever.** If you lose the keystore (or its passwords) you can no
> longer publish updates to the same Google Play listing — you'd have to ship a brand-new app.
> Store it in a password manager / secure vault, not on a single laptop. Never commit it.

**b) Create `android/key.properties`** (this file is gitignored — never commit it):

```properties
storePassword=<the store password you chose>
keyPassword=<the key password you chose>
keyAlias=upload
storeFile=/Users/you/uniun-upload-keystore.jks
```

`storeFile` is resolved relative to the `android/` folder, so an absolute path is safest. If you
place the keystore inside `android/`, a relative path like `storeFile=upload-keystore.jks` also
works (it's gitignored).

If `key.properties` is missing, the build falls back to no release signing and the resulting
`.aab` will not be accepted by the Play Store.

### iOS — Apple signing

iOS signing is managed by Xcode / Apple, not by a file in the repo. You need:

- An **Apple Developer Program** membership (the team that owns the `in.uniun.app` bundle ID).
- A **Distribution certificate** and an **App Store provisioning profile** for the bundle ID.
- The signing **Team** selected in Xcode: open `ios/Runner.xcworkspace` → *Runner* target →
  *Signing & Capabilities*. "Automatically manage signing" is the simplest path; Xcode then
  fetches/creates the cert + profile for you.
- An **App Store Connect** record for the app (created once, under the same bundle ID) before
  the first upload.

Building an `.ipa` for the store requires running on macOS with Xcode installed.

---

## 4. Build the release artifacts

Clean first if you changed dependencies or native config:

```bash
flutter clean && flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # if models/freezed changed
```

### iOS

```bash
flutter build ipa --release
```

Output: `build/ios/ipa/*.ipa`.

Upload the `.ipa` to App Store Connect with **Transporter**, Xcode's *Organizer*, or
`xcrun altool` from the command line:

```bash
xcrun altool --upload-app --type ios \
  -f build/ios/ipa/*.ipa \
  --apiKey <API_KEY_ID> \
  --apiIssuer <ISSUER_ID>
```

> **Add your own App Store Connect API credentials — never commit them.**
> - `<API_KEY_ID>` and `<ISSUER_ID>` come from **App Store Connect → Users and Access →
>   Integrations → App Store Connect API**: the key's *Key ID* and the team's *Issuer ID*.
> - Download that key's `AuthKey_<API_KEY_ID>.p8` once and place it in
>   `~/.appstoreconnect/private_keys/` (or `~/private_keys/`) so `altool` can find it.
> - Keep the key ID, issuer ID, and the `.p8` file out of the repository (e.g. export them as
>   shell env vars or pass them on the command line at upload time).

### Android

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`. Upload the **`.aab`** (App Bundle)
to the Google Play Console — Play prefers App Bundles over APKs. (For local sideloading/testing
only, `flutter build apk --release` produces a signed `.apk`.)

### Windows

Windows requires no signing setup. Run on a Windows machine:

```powershell
flutter build windows --release
flutter pub run build_runner build --delete-conflicting-outputs   # if models/freezed changed
```

Output: `build\windows\x64\runner\Release\`

**The installer is built in CI** when the release PR is merged (see
[Automatic GitHub release](#automatic-github-release)). To build it by hand, install
[Inno Setup](https://jrsoftware.org/isdl.php) and run:

```powershell
& "C:\Users\<you>\AppData\Local\Programs\Inno Setup 6\ISCC.exe" /DMyAppVersion=X.Y.Z installer\uniun_installer.iss
```

Output: `installer\output\uniun-setup-vX.Y.Z.exe`. The script packs the whole Release folder,
so a renamed plugin DLL needs no edit.

> The installer uses `windows\runner\resources\app_icon.ico` as its icon. Inno Setup is
> installed per-user at `AppData\Local\Programs\Inno Setup 6\` on most machines — adjust
> the path above if yours differs (`where /r C:\ ISCC.exe` finds it).

---

## 5. Upload & tag

### Automatic GitHub release

Open the release PR from a branch named `release/vX.Y.Z` (bumped `pubspec.yaml` and a
`## [X.Y.Z]` section in `CHANGELOG.md`). When it is merged into main,
`.github/workflows/release.yml`:

1. checks the branch name, that tag `VX.Y.Z` does not exist yet, that `pubspec.yaml` says
   `X.Y.Z+<build>` and that the changelog has the section;
2. builds the Windows app and `uniun-setup-vX.Y.Z.exe` on a Windows runner (with the real
   LFS embedding model);
3. tags the merge commit `VX.Y.Z` and publishes the GitHub Release with the installer, its
   SHA-256, and the changelog section plus store links as notes.

If a job fails, fix the cause and use **Re-run failed jobs** on that run. Steps 1 and 2 below
(the stores) are still manual, and so are steps 3 and 4 when the workflow did not run.

1. **Android** → Google Play Console → create a new release on the target track
   (internal / closed / production), upload the `.aab`, paste the changelog into "What's New".
2. **iOS** → App Store Connect → select the uploaded build, fill release notes, submit for review.
3. **Windows** → GitHub Releases → create a new release for the tag, upload
   `uniun-setup-vX.Y.Z.exe`, paste the contents of `RELEASE_NOTES_vX.Y.Z.md` as the
   description, and link to the App Store and Play Store for mobile users.
4. **Tag the commit** so the release is reproducible:

   ```bash
   git tag -a v1.2.0 -m "Release 1.2.0"
   git push origin v1.2.0
   ```

---

## Quick checklist

- [ ] `version:` bumped in `pubspec.yaml` (name **and** `+build`, build number increased).
- [ ] New section added to `CHANGELOG.md`.
- [ ] `android/key.properties` present and points to a valid keystore (Android).
- [ ] Xcode signing/team + App Store Connect record ready (iOS).
- [ ] `flutter build ipa --release` succeeds.
- [ ] `flutter build appbundle --release` succeeds.
- [ ] `flutter build windows --release` succeeds (Windows machine).
- [ ] Release PR branch is `release/vX.Y.Z`; after merge the Release workflow published `VX.Y.Z` with the installer.
- [ ] Artifacts uploaded; release notes match the changelog.
- [ ] Commit tagged `vX.Y.Z` and pushed.
