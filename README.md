# AltitudeNow

[![CI](https://github.com/jiejuefuyou/autoapp-altitude-now/actions/workflows/ci.yml/badge.svg)](https://github.com/jiejuefuyou/autoapp-altitude-now/actions/workflows/ci.yml)
[![Privacy: zero data](https://img.shields.io/badge/privacy-zero%20data%20collected-blue)](PRIVACY.md)
[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey)]()
[![Swift](https://img.shields.io/badge/swift-5.9-orange)]()

> Live altitude + barometric pressure logger for iOS. Zero network. Zero analytics.

The second product in the **AutoApp** experiment — an iOS app developed and operated end-to-end by an autonomous Claude Code agent.

## What it does

Reads the iPhone's built-in barometric pressure sensor (`CMAltimeter`, available on iPhone 6+) and shows:

- Live relative altitude (meters / feet)
- Live atmospheric pressure (hPa / inHg)
- A real-time chart of altitude over the current session
- A persisted log of past sessions, with min/max/gain stats and miniature chart per session

No GPS. No internet. No accounts. Nothing leaves the device.

## Pricing

- **Free** — live readings, last 1 session retained
- **Premium** — one-time **$2.99** non-consumable IAP — unlimited session history, custom calibration offset, CSV export, charts in session detail

## Tech

| Layer | Choice |
|---|---|
| UI | SwiftUI (iOS 17+), Swift Charts |
| Sensor | `CMAltimeter` (Core Motion) |
| Persistence | JSON in app sandbox |
| IAP | StoreKit 2 |
| Project | XcodeGen — `project.yml` is source of truth |
| Signing | fastlane match (shared `autoapp-certs` repo) |
| CI/CD | GitHub Actions on `macos-15` |

## Build locally

```sh
brew install xcodegen
xcodegen generate
open AltitudeNow.xcodeproj
```

The barometric sensor is **not** simulated by the iOS Simulator — to actually see live data, deploy to a physical iPhone.

## CI

- `ci.yml`: build + tests on every PR / main push
- `testflight.yml`: tag `v*` or manual dispatch → fastlane beta lane → TestFlight
- `init_signing.yml`: one-time, manual — bootstraps signing certs into `autoapp-certs` (no Mac required)

## Status

Phase 0 — scaffold complete, awaiting App Store Connect API key for first signed build.

See [PRIVACY.md](PRIVACY.md).
