# Security Policy

## Supported versions

The latest TestFlight / App Store build of AltitudeNow is the only supported version.

## Reporting a vulnerability

Please **do not** file public GitHub issues for security vulnerabilities.

Email: jiejuefuyou@gmail.com — subject line `SECURITY: AltitudeNow`. Expect an acknowledgement within 7 days. Coordinated disclosure preferred; we will work with you on a fix and credit you in the release notes if you wish.

## Scope

In scope:
- Code in this repository
- The build pipeline (GitHub Actions, fastlane, signing)
- The shipped app's handling of sensor data and locally-stored sessions

Out of scope:
- Apple's StoreKit / App Store / TestFlight / Core Motion infrastructure (report to Apple)
- iOS framework bugs not specific to our usage

## Threat model

AltitudeNow has no network surface, no user accounts, and reads only the device's barometric pressure sensor. The realistic attack surface is:
- Tampering with `altitudenow_state.json` in the app's Documents directory by an attacker with filesystem access
- Crafted CSV filenames in the export path (already sanitized in `CSVExporter.writeTempCSV`)
- Supply-chain attacks against fastlane gems — covered by GitHub-hosted runner isolation
