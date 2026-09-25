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
#   packaging/craft/craft-macos.sh --package  craft packaging; FAILS on macOS, see README.md (use hdiutil)
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
