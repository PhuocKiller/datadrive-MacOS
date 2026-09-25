#!/bin/zsh
# SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Builds DataDrive.app for macOS on an Intel Mac with KDE Craft.
#
# Runs the same craft commands as admin/osx/mac-crafter, without its Homebrew step:
# Homebrew no longer installs on Intel Macs. Python 3.12 and Inkscape come from
# $DATADRIVE_TOOLS/bin instead (see README.md, "macOS").
#
#   packaging/craft/craft-macos.sh            configure + compile + install the client
#   packaging/craft/craft-macos.sh --setup    first run: craftmaster, blueprints, dependencies
#   packaging/craft/craft-macos.sh --bundle [version]    after a build: clean, sign, make the DMG
#   packaging/craft/craft-macos.sh --notarize [version]  then: notarize and staple app and DMG, check with spctl
#   packaging/craft/craft-macos.sh --package  craft packaging; FAILS on macOS, see README.md
#
# The app lands in $DATADRIVE_BUILD/macos-64-clang/build/nextcloud-client/image-RelWithDebInfo-master/DataDrive.app

set -euo pipefail

REPO=${0:A:h:h:h}
TOOLS=${DATADRIVE_TOOLS:-$HOME/DataDrive_Tools}
BUILD=${DATADRIVE_BUILD:-$HOME/DataDrive_MacBuild}
TARGET=macos-64-clang
BLUEPRINT=nextcloud-client

export PATH="$TOOLS/bin:/usr/bin:/bin:/usr/sbin:/sbin"
# GenerateIconsUtils.cmake looks for inkscape here too
export SVG_CONVERTER_DIR="$TOOLS/bin"

craft() {
    python3 "$BUILD/craftmaster/CraftMaster.py" --config "$REPO/craftmaster.ini" --target "$TARGET" -c "$@"
}

mkdir -p "$BUILD"

if [[ ${1:-} == --setup ]]; then
    [[ -d $BUILD/craftmaster ]] || git clone --depth=1 https://invent.kde.org/packaging/craftmaster.git "$BUILD/craftmaster"
    # Same blueprint branches as the Windows build and the stable-34.0 binary cache in craftmaster.ini
    craft --add-blueprint-repository "https://github.com/nextcloud/craft-blueprints-kde.git|stable-34.0|"
    craft --add-blueprint-repository "https://github.com/nextcloud/craft-blueprints-nextcloud.git|stable-34.0|"
    craft craft
    craft --install-deps "$BLUEPRINT"
    exit 0
fi

# No sparkleLibPath: the auto-updater stays off, as in NEXTCLOUD.cmake.
craftOptions=(
    --options "$BLUEPRINT.srcDir=$REPO"
    --options "$BLUEPRINT.osxArchs=x86_64"
    --options "$BLUEPRINT.buildTests=False"
    --options "$BLUEPRINT.buildMacOSBundle=True"
    --options "$BLUEPRINT.buildFileProviderModule=True"
    --options "$BLUEPRINT.devMode=False"
)

# Signs DataDrive.app from the inside out, the way admin/osx/mac-crafter does: hardened runtime,
# secure timestamp, and entitlements only on the main app, the Finder extension and its login item.
# DATADRIVE_SIGN_IDENTITY picks the certificate, e.g. "Developer ID Application: Phuoc Tran (9BHT63MRZH)";
# without it the app is signed ad-hoc, which runs here but not as a Finder extension or on other Macs.
signBundle() {
    local app=$1
    local identity=${DATADRIVE_SIGN_IDENTITY:--}
    local entitlementsDir="$BUILD/$TARGET/build/$BLUEPRINT/work/build"
    local sign=(codesign --force --options=runtime --sign "$identity")
    if [[ $identity == - ]]; then
        sign+=(--timestamp=none)
    else
        sign+=(--timestamp)
    fi

    # 1. Every loose Mach-O file: dylibs, Qt plugins, extra executables such as datadrivecmd.
    #    Framework binaries and bundle main executables are signed with their bundle below.
    local file
    find "$app" -type f ! -path '*.framework/*' -print0 | while IFS= read -r -d '' file; do
        file -b "$file" | grep -q Mach-O || continue
        local contents=${file%/MacOS/*}
        if [[ $contents != "$file" && -f "$contents/Info.plist" ]] \
            && [[ "$(plutil -extract CFBundleExecutable raw "$contents/Info.plist" 2>/dev/null)" == "${file##*/}" ]]; then
            continue
        fi
        "${sign[@]}" "$file"
    done

    # 2. Frameworks, deepest first.
    find "$app" -type d -name '*.framework' | awk '{ print length, $0 }' | sort -rn | cut -d' ' -f2- | while IFS= read -r file; do
        "${sign[@]}" "$file"
    done

    # 3. The extensions (Finder Sync, File Provider and its UI) and the Finder Sync login item, each
    #    with the entitlements file named after it.
    for file in "$app"/Contents/PlugIns/*.appex; do
        [[ -d $file ]] || continue
        local entitlements="$entitlementsDir/shell_integration/MacOSX/${${file##*/}%.appex}.entitlements"
        [[ -f $entitlements ]] || { echo "No entitlements for $file" >&2; exit 1; }
        "${sign[@]}" --entitlements "$entitlements" "$file"
    done
    for file in "$app"/Contents/Library/LoginItems/*.app; do
        [[ -d $file ]] && "${sign[@]}" --entitlements "$entitlementsDir/shell_integration/MacOSX/FinderSyncBroker.entitlements" "$file"
    done

    # 4. The app itself.
    "${sign[@]}" --entitlements "$entitlementsDir/admin/osx/macosx.entitlements" "$app"
    codesign --verify --deep --strict --verbose=2 "$app"
}

# A DMG with the app and a link to /Applications to drag it onto.
makeDmg() {
    local app=$1 dmg=$2 staging
    staging=$(mktemp -d)
    cp -R "$app" "$staging/" && ln -s /Applications "$staging/Applications"
    rm -f "$dmg"
    hdiutil create -volname DataDrive -srcfolder "$staging" -fs HFS+ -format UDZO -imagekey zlib-level=9 "$dmg"
    rm -rf "$staging"
    hdiutil verify "$dmg"
    echo "$dmg"
}

if [[ ${1:-} == --bundle ]]; then
    # Turns the installed app into something that runs anywhere, then wraps it in a DMG.
    # Every Mach-O file keeps an LC_RPATH to $BUILD/$TARGET/lib next to its bundle-relative one.
    # dyld tries it first, so on this machine the app loads a second copy of Qt from craft and
    # aborts with "Cannot add multiple registrations for QtQuick.Templates".
    image="$BUILD/$TARGET/build/$BLUEPRINT/image-RelWithDebInfo-master/DataDrive.app"
    dist="$BUILD/dist"
    app="$dist/DataDrive.app"
    version=${2:-1.0.0}
    rm -rf "$app"; mkdir -p "$dist"; cp -R "$image" "$app"

    # Raw copies of the sync libraries from the CMake install; both executables load the ones in Frameworks.
    rm -f "$app"/Contents/MacOS/lib*.dylib

    machoFiles=("${(@f)$(find "$app" -type f -exec sh -c 'file -b "$1" | grep -q Mach-O && echo "$1"' _ {} \;)}")
    for f in "${machoFiles[@]}"; do
        for rpath in $(otool -l "$f" | awk '$1 == "cmd" && $2 == "LC_RPATH" {getline; getline; print $2}' | grep "^$BUILD/" || true); do
            install_name_tool -delete_rpath "$rpath" "$f"
        done
    done

    # otool -L starts with the file's own path, which is under $BUILD/dist, hence tail and the craft root only
    leftovers=$(for f in "${machoFiles[@]}"; do otool -L "$f" | tail -n +2; otool -l "$f" | grep -A2 LC_RPATH; done | grep -c "$BUILD/$TARGET/" || true)
    if (( leftovers > 0 )); then
        echo "DataDrive.app still references $BUILD/$TARGET in $leftovers places" >&2
        exit 1
    fi

    signBundle "$app"
    makeDmg "$app" "$dist/DataDrive-$version-macos-x86_64.dmg"
    exit 0
fi

if [[ ${1:-} == --notarize ]]; then
    # After --bundle with DATADRIVE_SIGN_IDENTITY set. Notarizes the app and staples it, rebuilds the
    # DMG around the stapled app, then signs, notarizes and staples the DMG, so both open offline.
    # Needs an App Store Connect API key: DATADRIVE_NOTARY_KEY_ID, DATADRIVE_NOTARY_ISSUER and
    # ~/.appstoreconnect/private_keys/AuthKey_<key id>.p8.
    : "${DATADRIVE_SIGN_IDENTITY:?set it to the Developer ID Application certificate}"
    : "${DATADRIVE_NOTARY_KEY_ID:?}" "${DATADRIVE_NOTARY_ISSUER:?}"
    dist="$BUILD/dist"
    app="$dist/DataDrive.app"
    dmg="$dist/DataDrive-${2:-1.0.0}-macos-x86_64.dmg"
    keyFile="$HOME/.appstoreconnect/private_keys/AuthKey_$DATADRIVE_NOTARY_KEY_ID.p8"

    notarize() {
        local result
        result=$(xcrun notarytool submit "$1" --key "$keyFile" --key-id "$DATADRIVE_NOTARY_KEY_ID" \
            --issuer "$DATADRIVE_NOTARY_ISSUER" --wait --timeout 1h --output-format json)
        echo "$result"
        local id=$(echo "$result" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("id", ""))')
        if [[ $(echo "$result" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status", ""))') != Accepted ]]; then
            [[ -n $id ]] && xcrun notarytool log "$id" --key "$keyFile" --key-id "$DATADRIVE_NOTARY_KEY_ID" --issuer "$DATADRIVE_NOTARY_ISSUER"
            echo "Notarization of $1 was not accepted" >&2
            exit 1
        fi
    }

    zip="$dist/DataDrive-notarize.zip"
    ditto -c -k --keepParent "$app" "$zip"
    notarize "$zip"
    rm -f "$zip"
    xcrun stapler staple "$app"

    makeDmg "$app" "$dmg"
    codesign --force --sign "$DATADRIVE_SIGN_IDENTITY" --timestamp "$dmg"
    notarize "$dmg"
    xcrun stapler staple "$dmg"

    xcrun stapler validate "$dmg"
    spctl -a -vv -t exec "$app"
    spctl -a -vv -t open --context context:primary-signature "$dmg"
    exit 0
fi

if [[ ${1:-} == --package ]]; then
    # The upstream blueprint cannot package a rebranded client (see README.md), and craft syncs
    # its blueprint directory with git, so the patched copies go back in before every package run.
    blueprintDir="$BUILD/$TARGET/etc/blueprints/locations/craft-blueprints-nextcloud/$BLUEPRINT"
    cp "$REPO/packaging/craft/nextcloud-client.py" "$REPO/packaging/craft/blacklist.txt" \
        "$REPO/packaging/craft/uninstall-cleanup.ps1" "$blueprintDir/"
    craft --buildtype RelWithDebInfo --package "${craftOptions[@]}" "$BLUEPRINT"
    exit 0
fi

# Listing the actions explicitly: a bare "craft nextcloud-client" may decide it is up to date
# and compile nothing.
craft --buildtype RelWithDebInfo --configure --compile --install "${craftOptions[@]}" "$BLUEPRINT"
