.PHONY: help build-mac build-android build-android-play run-mac run-phone test format analyze

help:
	@echo "Available commands in AndroMac monorepo:"
	@echo "  make build-mac          - Build macOS desktop app in apps/desktop"
	@echo "  make build-android      - Build Android APK (direct flavor) in apps/phone"
	@echo "  make build-android-play - Build Android App Bundle (play flavor) in apps/phone"
	@echo "  make run-mac            - Run macOS desktop app in apps/desktop"
	@echo "  make run-phone          - Run Android app in apps/phone"
	@echo "  make test               - Run all unit and integration tests"
	@echo "  make format             - Format all Dart files across the monorepo"
	@echo "  make analyze            - Run static analyzer with fatal infos"

build-mac:
	cd apps/desktop && flutter build macos --release

build-android:
	cd apps/phone && flutter build apk --flavor direct --release

build-android-play:
	cd apps/phone && flutter build appbundle --flavor play --release

run-mac:
	cd apps/desktop && flutter run -d macos

run-phone:
	cd apps/phone && flutter run -d android

test:
	dart test test/ $$(find packages tools apps -name "*_test.dart")

format:
	dart format .

analyze:
	dart analyze --fatal-infos
