#!/bin/zsh
# SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Stands in for macdeployqt when craft-macos.sh --arm64 cross-compiles on an Intel Mac.
#
# The arm64 craft root only has an arm64 macdeployqt, which cannot run here. This runs the x86_64
# one from the host root, points its -libpath at the arm64 root, then swaps in the arm64 copy of
# every Mach-O file it still took from the host Qt (plugins and QML plugins come from its own
# QLibraryInfo paths). macdeployqt flattens QML plugins into PlugIns/quick, hence the lookup by name.
#
#   craft-macdeployqt-arm64.sh <macdeployqt arguments>
#   craft-macdeployqt-arm64.sh --fix <DataDrive.app>    only the swap

BUILD=${DATADRIVE_BUILD:-$HOME/DataDrive_MacBuild}
X=$BUILD/macos-64-clang
A=$BUILD/macos-clang-arm64

if [[ $1 == --fix ]]; then
    shift
else
    $X/bin/macdeployqt "${@//-libpath=$X\/lib/-libpath=$A/lib}" || exit $?
fi

app=${1:A}
missing=0
find "$app" -type f -print0 | while IFS= read -r -d '' f; do
    file -b "$f" | grep -q Mach-O || continue
    lipo -archs "$f" 2>/dev/null | grep -qw arm64 && continue
    rel=${f#$app/Contents/}
    case $rel in
        Frameworks/*) src=$A/lib/${rel#Frameworks/} ;;
        PlugIns/*) src=$A/plugins/${rel#PlugIns/} ;;
        Resources/qml/*) src=$A/qml/${rel#Resources/qml/} ;;
        *) src= ;;
    esac
    [[ -n $src && -f $src ]] || src=$(find $A/qml $A/plugins -name "${f:t}" -type f | head -1)
    if [[ -n $src && -f $src ]]; then
        # Carry over macdeployqt's install name rewrites (absolute craft paths to @executable_path/../Frameworks).
        # The first entry of otool -D is the file's own id, empty for plugins.
        local id=$(otool -D "$f" | tail -n +2)
        local -A deployed=()
        local dep
        for dep in $(otool -L "$f" | tail -n +2 | awk '{ print $1 }'); do
            deployed[${dep:t}]=$dep
        done
        cp -f "$src" "$f"
        local changes=()
        [[ -n $id ]] && changes+=(-id "$id")
        for dep in $(otool -L "$f" | tail -n +2 | awk '{ print $1 }'); do
            [[ -n ${deployed[${dep:t}]} && ${deployed[${dep:t}]} != "$dep" ]] && changes+=(-change "$dep" "${deployed[${dep:t}]}")
        done
        (( ${#changes} )) && install_name_tool "${changes[@]}" "$f" 2>/dev/null
    else
        echo "No arm64 copy of $f" >&2
        missing=1
    fi
done
exit $missing
