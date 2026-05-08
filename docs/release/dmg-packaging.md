# tidy DMG packaging

The release DMG is built by `scripts/build-dmg.sh`.

## Default command

```bash
./scripts/build-dmg.sh
```

This command:

- builds the macOS app from `TodoApp/TodoApp.xcodeproj`
- outputs a release app bundle named `tidy.app`
- verifies the staged app bundle signature and applies an ad-hoc signature when needed
- creates a DMG named `dist/tidy-macOS-v<version>.dmg`
- sets the mounted volume name to `tidy`
- writes a Finder layout with `tidy.app` on the left and `Applications` on the right
- uses `packaging/dmg/background.png` if present, otherwise generates a basic background automatically

## Signing behavior

The default package does not require an Apple Developer account. If the built app
does not already have a valid bundle signature, the packaging script applies a
local ad-hoc signature before creating the DMG.

This keeps the app bundle structurally valid for macOS, but it does not notarize
the app. First-time users may still need to allow the app from System Settings >
Privacy & Security with Open Anyway.

## Optional overrides

```bash
APP_BUNDLE_PATH="/absolute/path/to/tidy.app" ./scripts/build-dmg.sh
DMG_BACKGROUND_PATH="/absolute/path/to/custom-background.png" ./scripts/build-dmg.sh
```

## Naming controls

The release user-visible name `tidy` is driven by:

- `PRODUCT_NAME = tidy` in the Release configuration in `TodoApp/TodoApp.xcodeproj/project.pbxproj`
- `CFBundleName = tidy` in the generated Release app Info.plist via `INFOPLIST_KEY_CFBundleName`
- `CFBundleDisplayName = tidy` in the generated Release app Info.plist via `INFOPLIST_KEY_CFBundleDisplayName`
- `APP_NAME=tidy` in `scripts/build-dmg.sh` for the DMG filename and staged app name
- `VOLUME_NAME=tidy` in `scripts/build-dmg.sh` for the mounted disk name

The Debug configuration intentionally builds `tidy Demo.app` with bundle identifier `com.todoapp.TodoApp.demo` so local inspection does not collide with the installed release app.

The internal Swift target and module remain `TodoApp`, so imports and source layout do not need a wide refactor.

## Replaceable assets

- Preferred custom background path: `packaging/dmg/background.png`
- Fallback generator: `packaging/dmg/generate_background.swift`

If you later add a brand-specific background PNG, place it at `packaging/dmg/background.png` or pass `DMG_BACKGROUND_PATH`.
