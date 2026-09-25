/*
 * SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <QString>

namespace OCC
{

/**
 * Locks the local sync folder of a signed-out account, so it cannot be opened until the account
 * logs in again. The folder gets mode 000, which Finder shows as a folder you have no permission
 * to open; the original mode is kept in the settings and restored on unlock.
 *
 * This keeps the files away from other people using the same computer account through Finder. It
 * is not encryption: the owner can still chmod the folder back in a terminal.
 *
 * Only a folder whose sync has stopped may be locked, and it has to be unlocked before its next
 * sync: a sync run that cannot read the folder must never get to decide what changed. Unix only;
 * on Windows every function returns false.
 */
namespace FolderLock
{

/// Locks @p path and remembers its mode. True if the folder is locked afterwards.
bool lock(const QString &path);

/// Restores the mode saved by lock(). False if @p path was not locked by lock() or chmod failed.
bool unlock(const QString &path);

/// True if lock() locked @p path and it has not been unlocked since.
[[nodiscard]] bool isLocked(const QString &path);

}

}
