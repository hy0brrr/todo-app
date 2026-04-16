# tidy DMG packaging

The release DMG is built by `scripts/build-dmg.sh`.

## Default command

```bash
./scripts/build-dmg.sh
```

This command:

- builds the macOS app from `TodoApp/TodoApp.xcodeproj`
- outputs a release app bundle named `tidy.app`
- creates a DMG named `dist/tidy-macOS-v<version>.dmg`
- sets the mounted volume name to `tidy`
- writes a Finder layout with `tidy.app` on the left and `Applications` on the right
- uses `packaging/dmg/background.png` if present, otherwise generates a basic background automatically

## Optional overrides

```bash
APP_BUNDLE_PATH="/absolute/path/to/tidy.app" ./scripts/build-dmg.sh
DMG_BACKGROUND_PATH="/absolute/path/to/custom-background.png" ./scripts/build-dmg.sh
```

## Naming controls

The user-visible name `tidy` is driven by:

- `PRODUCT_NAME = tidy` in `TodoApp/TodoApp.xcodeproj/project.pbxproj`
- `CFBundleName = tidy` in the generated app Info.plist via `INFOPLIST_KEY_CFBundleName`
- `CFBundleDisplayName = tidy` in the generated app Info.plist via `INFOPLIST_KEY_CFBundleDisplayName`
- `APP_NAME=tidy` in `scripts/build-dmg.sh` for the DMG filename and staged app name
- `VOLUME_NAME=tidy` in `scripts/build-dmg.sh` for the mounted disk name

The internal Swift target and module remain `TodoApp`, so imports and source layout do not need a wide refactor.

## Replaceable assets

- Preferred custom background path: `packaging/dmg/background.png`
- Fallback generator: `packaging/dmg/generate_background.swift`

If you later add a brand-specific background PNG, place it at `packaging/dmg/background.png` or pass `DMG_BACKGROUND_PATH`.
