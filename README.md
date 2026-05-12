# MacFanControl

Tiny macOS menu bar app to view fan RPM and switch each fan between Auto / Silent / Balanced / Full.

## Requirements

- macOS 26.0+, Apple Silicon (M1–M4)
- Xcode 26.4+, Swift 6.3
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen` (regenerates `MacFanControl.xcodeproj` from `project.yml`)

## Build

```sh
cp Signing.example.xcconfig Signing.local.xcconfig   # then fill in your cert + team ID
xcodegen generate
xcodebuild -scheme MacFanControl -destination 'platform=macOS,arch=arm64' build
open ~/Library/Developer/Xcode/DerivedData/MacFanControl-*/Build/Products/Debug/MacFanControl.app
```

`Signing.local.xcconfig` is gitignored. Find your identity SHA1 with
`security find-identity -v -p codesigning` and the team ID is the parenthesized
10-character code in the certificate name. The helper derives the *expected*
client team ID from its own signature at startup, so you don't have to set it
anywhere else — whoever signs the helper transitively decides which apps may
talk to it.

The first launch prompts to install a privileged helper (used for SMC writes — required to change fan mode). Approve in **System Settings → General → Login Items & Extensions**.

## Tests

```sh
swift test
```

## Architecture

`SMCKit` (raw SMC I/O) → `FanDomain` (Fan / FanService) → `HelperIPC` (XPC contract) → App (SwiftUI MenuBarExtra) + Helper (root LaunchDaemon via `SMAppService`).

App Sandbox is disabled — privileged Mach-service daemons are not compatible with the sandbox, which also means MacFanControl cannot ship via the Mac App Store.
