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
#   packaging/craft/craft-macos.sh --bundle [version]  after a build: clean, sign ad-hoc, make the DMG
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
    --options "$BLUEPRINT.buildFileProviderModule=False"
    --options "$BLUEPRINT.devMode=False"
)

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

    # Ad-hoc until there is a Developer ID Application certificate; the Finder extension will not load unsigned.
    codesign --force --deep --sign - --timestamp=none "$app"
    codesign --verify --deep --strict "$app"

    dmg="$dist/DataDrive-$version-macos-x86_64.dmg"
    staging=$(mktemp -d)
    cp -R "$app" "$staging/" && ln -s /Applications "$staging/Applications"
    rm -f "$dmg"
    hdiutil create -volname DataDrive -srcfolder "$staging" -fs HFS+ -format UDZO -imagekey zlib-level=9 "$dmg"
    rm -rf "$staging"
    hdiutil verify "$dmg"
    echo "$dmg"
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
