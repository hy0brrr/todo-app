#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PROJECT_PATH="${PROJECT_PATH:-${REPO_ROOT}/TodoApp/TodoApp.xcodeproj}"
SCHEME="${SCHEME:-TodoApp}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${REPO_ROOT}/.build-dmg-xcode}"
DIST_DIR="${DIST_DIR:-${REPO_ROOT}/dist}"
APP_NAME="${APP_NAME:-tidy}"
VOLUME_NAME="${VOLUME_NAME:-tidy}"
WINDOW_WIDTH="${WINDOW_WIDTH:-620}"
WINDOW_HEIGHT="${WINDOW_HEIGHT:-360}"
APP_ICON_X="${APP_ICON_X:-175}"
APP_ICON_Y="${APP_ICON_Y:-140}"
APPLICATIONS_ICON_X="${APPLICATIONS_ICON_X:-445}"
APPLICATIONS_ICON_Y="${APPLICATIONS_ICON_Y:-140}"
CUSTOM_BACKGROUND_PATH="${DMG_BACKGROUND_PATH:-${REPO_ROOT}/packaging/dmg/background.png}"
BACKGROUND_GENERATOR="${REPO_ROOT}/packaging/dmg/generate_background.swift"
APPLICATIONS_ICON_SOURCE="${APPLICATIONS_ICON_SOURCE:-/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ApplicationsFolderIcon.icns}"

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/tidy-dmg.XXXXXX")"
work_dir="$(cd "${work_dir}" && pwd -P)"
mount_root="${work_dir}/mount-root"
mount_point="${mount_root}/${VOLUME_NAME}"
staging_dir="${work_dir}/staging"
rw_dmg="${work_dir}/tidy-temp.dmg"

cleanup() {
    if mount | grep -Fq "on ${mount_point} "; then
        hdiutil detach "${mount_point}" -force -quiet || true
    fi
    rm -rf "${work_dir}"
}
trap cleanup EXIT

detach_existing_volumes() {
    shopt -s nullglob
    for mounted_path in /Volumes/"${VOLUME_NAME}"*; do
        mounted_name="$(basename "${mounted_path}")"
        case "${mounted_name}" in
            "${VOLUME_NAME}"|"${VOLUME_NAME} "[0-9]*)
                hdiutil detach "${mounted_path}" -force -quiet >/dev/null 2>&1 || true
                ;;
        esac
    done
    shopt -u nullglob
}

mkdir -p "${mount_root}" "${staging_dir}" "${DIST_DIR}"
detach_existing_volumes

if [[ -n "${APP_BUNDLE_PATH:-}" ]]; then
    app_bundle_path="${APP_BUNDLE_PATH}"
else
    xcodebuild \
        -project "${PROJECT_PATH}" \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -derivedDataPath "${DERIVED_DATA_PATH}" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        build
    app_bundle_path="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
fi

if [[ ! -d "${app_bundle_path}" ]]; then
    echo "App bundle not found at ${app_bundle_path}" >&2
    exit 1
fi

app_bundle_name="$(basename "${app_bundle_path}")"
version="$(
    /usr/libexec/PlistBuddy \
        -c "Print :CFBundleShortVersionString" \
        "${app_bundle_path}/Contents/Info.plist"
)"
dmg_basename="${APP_NAME}-macOS-v${version}"
output_stub="${DIST_DIR}/${dmg_basename}"
final_dmg="${output_stub}.dmg"

ditto "${app_bundle_path}" "${staging_dir}/${app_bundle_name}"

mkdir -p "${staging_dir}/.background"
if [[ -f "${CUSTOM_BACKGROUND_PATH}" ]]; then
    cp "${CUSTOM_BACKGROUND_PATH}" "${staging_dir}/.background/background.png"
else
    swift "${BACKGROUND_GENERATOR}" "${staging_dir}/.background/background.png" "${APP_NAME}" "${WINDOW_WIDTH}" "${WINDOW_HEIGHT}"
fi
chflags hidden "${staging_dir}/.background"

hdiutil create \
    -quiet \
    -ov \
    -srcfolder "${staging_dir}" \
    -volname "${VOLUME_NAME}" \
    -fs HFS+ \
    -format UDRW \
    "${rw_dmg}"

hdiutil attach \
    -quiet \
    -readwrite \
    -noverify \
    -noautoopen \
    -mountroot "${mount_root}" \
    "${rw_dmg}"

for _ in {1..10}; do
    if [[ -d "${mount_point}" ]]; then
        break
    fi
    sleep 1
done

if [[ ! -d "${mount_point}" ]]; then
    echo "Mounted DMG volume not found at ${mount_point}" >&2
    exit 1
fi

/usr/bin/osascript <<EOF
tell application "Finder"
    set mountFolder to POSIX file "${mount_point}" as alias
    try
        delete item "Applications" of mountFolder
    end try
    make new alias file at mountFolder to POSIX file "/Applications" with properties {name:"Applications"}
end tell
EOF

tmp_png="$(mktemp "${TMPDIR:-/tmp}/applications-icon.XXXXXX.png")"
tmp_rsrc="$(mktemp "${TMPDIR:-/tmp}/applications-icon.XXXXXX.rsrc")"
sips -s format png "${APPLICATIONS_ICON_SOURCE}" --out "${tmp_png}" >/dev/null
sips -i "${tmp_png}" >/dev/null
DeRez -only icns "${tmp_png}" > "${tmp_rsrc}"
Rez -append "${tmp_rsrc}" -o "${mount_point}/Applications"
SetFile -a C "${mount_point}/Applications"
rm -f "${tmp_png}" "${tmp_rsrc}"

/usr/bin/osascript <<EOF
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {120, 120, 120 + ${WINDOW_WIDTH}, 120 + ${WINDOW_HEIGHT}}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set text size of theViewOptions to 12
        set background color of theViewOptions to {65535, 65535, 65535}
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "${app_bundle_name}" of container window to {${APP_ICON_X}, ${APP_ICON_Y}}
        set position of item "Applications" of container window to {${APPLICATIONS_ICON_X}, ${APPLICATIONS_ICON_Y}}
        try
            set position of item ".background" of container window to {1200, 1200}
        end try
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

bless --folder "${mount_point}" --openfolder "${mount_point}" >/dev/null 2>&1 || true
sync
rm -rf "${mount_point}/.fseventsd" "${mount_point}/.Trashes"
hdiutil detach "${mount_point}" -quiet

rm -f "${final_dmg}" "${output_stub}"
hdiutil convert \
    -quiet \
    "${rw_dmg}" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${output_stub}"

echo "DMG created at ${final_dmg}"
