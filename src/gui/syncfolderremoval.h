/*
 * SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <QString>
#include <QStringList>

namespace OCC
{

class Folder;

/**
 * Deleting the local copy of a sync folder, shared by "Remove account" and the macOS uninstaller.
 *
 * The sync connection of a folder has to be removed before its files are deleted: a sync run that
 * sees the files disappear takes it as the user deleting them and deletes them on the server too.
 */
namespace SyncFolderRemoval
{

/// True when no run of @p folder is going on or paused and the last one ended cleanly. "Problem"
/// results carry ignored or blacklisted items, which are exactly the files only this computer has.
[[nodiscard]] bool isFullySynced(const Folder *folder);

/// Refuses paths that do not exist, the home folder, anything above it and anything less than two
/// levels deep, so a bad folder definition cannot take more than its own folder with it.
[[nodiscard]] bool isSafeToDelete(const QString &path);

/// One "• path" line per entry, for message boxes.
[[nodiscard]] QString bulletList(const QStringList &paths);

/// Deletes @p paths in the background once no sync folder uses them any more. Call it only after
/// the sync connections of those folders have been removed.
void deleteLocalCopies(const QStringList &paths);

}

}
