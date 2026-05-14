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

### Makefile shortcuts

A `Makefile` wraps the common workflows so you don't have to remember the
xcodebuild incantations. Output goes to `./build/` instead of `DerivedData`.

```sh
make help        # list all targets
make generate    # xcodegen generate (also runs automatically as needed)
make build       # Debug build
make release     # Release build -> build/Build/Products/Release/MacFanControl.app
make run         # Release build, then open the app
make run-debug   # Debug build, then open the app
make test        # swift test
make clean       # remove build/
```

Override the defaults via env vars, e.g. `make build SCHEME=MacFanControl DESTINATION='platform=macOS,arch=arm64'`.

## Tests

```sh
swift test       # or: make test
```

## Architecture

`SMCKit` (raw SMC I/O) → `FanDomain` (Fan / FanService) → `HelperIPC` (XPC contract) → App (SwiftUI MenuBarExtra) + Helper (root LaunchDaemon via `SMAppService`).

App Sandbox is disabled — privileged Mach-service daemons are not compatible with the sandbox, which also means MacFanControl cannot ship via the Mac App Store.
