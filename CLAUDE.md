# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AndroMac** (Bridge) is a local-first, privacy-first integration system connecting Android and macOS devices (clipboard sharing, notification mirroring, SMS client, screen control, file transfer). The architecture centers on a shared Dart/Flutter codebase with native platform modules in Kotlin (Android) and Swift (macOS).

## High-Level Architecture

- **Communication Model**: Symmetric peer-to-peer over LAN using mTLS + WebSockets.
  - Discovery: mDNS/DNS-SD (`_bridge._tcp`), fallback to manual IP/port or QR code pairing.
  - Wire Protocol: JSON envelope (`v`, `id`, `type`, `ts`, `ref`, `payload`) with 15s ping/pong heartbeats and exponential backoff reconnection.
- **Repository Structure (Target Monorepo)**:
  - `apps/phone`: Android Flutter app with native Kotlin background services (`ForegroundService`, `NotificationListenerService`, SMS content observer).
  - `apps/desktop`: macOS Flutter app with native Swift menu bar / tray integration, pasteboard observers, and `VideoToolbox`.
  - `packages/bridge_protocol`: Message models, serialization, protocol schemas, and golden contract test fixtures.
  - `packages/bridge_crypto`: Key generation, self-signed X.509 certs, certificate pinning, QR pairing, SAS verification.
  - `packages/bridge_transport`: Discovery (mDNS), mTLS WebSocket connection lifecycle, session resumption.
  - `packages/bridge_core`: Domain entities, feature registry (`BridgeFeature`), and encrypted persistence (`drift` + SQLCipher).
  - `packages/bridge_platform`: Type-safe Dart <-> Native channel interfaces generated via Pigeon.
  - `packages/bridge_ui`: Shared design system widgets and themes.
  - `packages/features/*`: Modular feature implementations (`clipboard`, `notifications`, `sms`, `remote_control`, `file_transfer`, `otp`, `device_status`).
  - `tools/fake_phone` & `tools/fake_mac`: Dart CLI emulators for synthetic event generation and decoupled development.
- **Key Architectural Constraints & Decisions**:
  - **Zero Cloud / Privacy-First**: All data stays on the local network; never log sensitive data (SMS, notifications, clipboard contents).
  - **Android Background**: Android runs a persistent `ForegroundService` hosting a headless `FlutterEngine` to maintain network connectivity.
  - **Android Clipboard**: Android 10+ blocks background clipboard reading; Android -> Mac clipboard sync requires explicit triggers (share-sheet, quick settings tile, or notification action).
  - **Remote Control (Screen)**: MVP leverages embedded `adb` + `scrcpy-server` via wireless debugging or USB tunnel (`adb forward/reverse`).
  - **Feature Contract**: Features implement `BridgeFeature` (`id`, `incomingTypes`, `start()`, `stop()`, `onMessage()`) and dynamically negotiate capabilities during handshake (`hello`/`hello.ack`).

## Development & Build Commands

### Environment & Workspace
- Enable macOS desktop support in Flutter:
  ```bash
  flutter config --enable-macos-desktop
  ```
- Dependency management (Melos / Dart Pub workspaces):
  ```bash
  dart pub get
  # or when using melos:
  melos bootstrap
  ```
- Code generation (Freezed, Riverpod, Drift):
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- Pigeon native interface code generation:
  ```bash
  dart run pigeon --input pigeons/<interface>.dart
  ```

### Linting & Formatting
- Code formatting check:
  ```bash
  dart format --set-exit-if-changed .
  ```
- Format code in-place:
  ```bash
  dart format .
  ```
- Static analysis:
  ```bash
  flutter analyze
  ```

### Testing
- Run all unit and widget tests:
  ```bash
  flutter test
  ```
- Run a single test file:
  ```bash
  flutter test test/path/to/test_file.dart
  ```
- Run a specific test by name:
  ```bash
  flutter test --plain-name "test description"
  ```
- Run integration tests:
  ```bash
  flutter test integration_test/app_test.dart
  ```

### Building
- macOS desktop application (run from `apps/desktop` or via root shortcuts):
  ```bash
  cd apps/desktop && flutter build macos --release
  # or from root:
  make build-mac
  # or:
  ./scripts/build_macos.sh
  ```
- Android APKs (run from `apps/phone` or via root shortcuts):
  ```bash
  cd apps/phone && flutter build apk --flavor direct --release   # Full-featured version (SMS, direct distribution)
  cd apps/phone && flutter build apk --flavor play --release     # Google Play compliant flavor
  # or from root:
  make build-android
  # or:
  ./scripts/build_android.sh
  ```

### Tools & Development Emulation
- Run fake phone CLI emulator:
  ```bash
  dart run tools/fake_phone/bin/fake_phone.dart
  ```
- Run fake Mac CLI emulator:
  ```bash
  dart run tools/fake_mac/bin/fake_mac.dart
  ```
- Android Emulator networking note: Connect to host Mac using `10.0.2.2:<port>` (mDNS does not bridge across Android emulator NAT).

## Development Team & Agent Roles

The project operates with a dedicated team of specialized subagents located in `.claude/agents/`:

1. **`team-lead` (Team Lead & Principal Architect)**:
   - Architecture oversight and adherence to local-first / privacy-first principles.
   - Performs code reviews on all PRs using `github-personal` MCP.
   - Approves (`APPROVE`) or requests changes (`REQUEST_CHANGES`), and merges approved PRs into `dev`.
2. **`core-protocol` (Core Protocol, Cryptography & Transport Engineer)**:
   - Focus: `packages/bridge_protocol`, `packages/bridge_crypto`, `packages/bridge_transport`, `packages/bridge_core`.
   - Wire protocol, mTLS WebSockets, mDNS discovery, X.509 certs, Drift/SQLCipher encrypted storage.
3. **`android-native` (Android Native & Platform Services Engineer)**:
   - Focus: `apps/phone/android` (Kotlin), `packages/bridge_platform` (Android Pigeon bindings).
   - `ForegroundService` + headless `FlutterEngine`, `NotificationListenerService`, SMS Observer/Sender, clipboard triggers.
4. **`macos-native` (macOS Native & System Integration Engineer)**:
   - Focus: `apps/desktop/macos` (Swift), `packages/bridge_platform` (macOS Pigeon bindings).
   - Menu bar tray app (`NSStatusItem`, popover), `NSPasteboard` change monitoring, `UNUserNotificationCenter`, sleep/wake events.
5. **`ui-features` (Flutter UI & Features Engineer)**:
   - Focus: `packages/bridge_ui`, `packages/features/*`, `apps/phone/lib`, `apps/desktop/lib`.
   - Riverpod state management, `BridgeFeature` implementations, QR pairing UI, settings, SMS conversations, localization.
6. **`qa-tester` (QA & Emulation Engineer)**:
   - Focus: `tools/fake_phone`, `tools/fake_mac`, test suites.
   - CLI synthetic emulators for independent development, protocol golden schema tests, chaos network testing.

## Git & Pull Request Workflow

### Branching Policy
- **Base Integration Branch**: `dev`. All development branches branch from `dev` and merge back into `dev`. `main` is reserved for tagged stable releases.
- **Branch Naming**:
  - Features: `feat/<feature-name>-<agent-role>` (e.g. `feat/wire-envelope-core`, `feat/notification-listener-android`)
  - Fixes: `fix/<issue-name>-<agent-role>`
  - Tests & Emulators: `test/<name>-qa`

### Development & Commit Rules
- Each milestone must be committed atomically with Conventional Commits (`feat:`, `fix:`, `test:`, `refactor:`, `docs:`).
- Commit attribution trailer required:
  ```
  Co-Authored-By: Claude Code <noreply@anthropic.com>
  ```
- Push commits to the remote branch frequently: `git push -u origin <branch-name>`.

### PR Lifecycle with GitHub MCP (`github-personal`)
1. **Creation**: The agent creates a PR targeting `dev`:
   - Tool: `mcp__github-personal__create_pull_request`
   - Parameters: `owner: "culcat"`, `repo: "AndroMac"`, `base: "dev"`, `head: "<branch-name>"`, `title`, `body`.
2. **Review**: `team-lead` reviews the PR:
   - Inspect details: `mcp__github-personal__pull_request_read` (`get`, `get_diff`, `get_files`).
   - Review comments: `mcp__github-personal__pull_request_review_write` (`REQUEST_CHANGES` or inline comments).
3. **Fix Loop**: Developer agent inspects comments, applies fixes, commits, pushes, and requests re-review.
4. **Approval & Merge**:
   - `team-lead` approves: `pull_request_review_write` with `event: "APPROVE"`.
   - `team-lead` merges: `mcp__github-personal__merge_pull_request` (squash or merge) into `dev`.

## External Documentation with Context7

Whenever working with frameworks, libraries, and SDKs (Flutter, Dart, Riverpod, Drift, Pigeon, Android SDK, AppKit/Swift):
- Call `mcp__context7__resolve-library-id` with the official library name.
- Call `mcp__context7__query-docs` with the specific topic to retrieve up-to-date documentation and code patterns.

