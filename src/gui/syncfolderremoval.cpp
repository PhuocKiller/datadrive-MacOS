/*
 * SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "syncfolderremoval.h"

#include "folder.h"
#include "folderlock.h"
#include "folderman.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QLoggingCategory>
#include <QThreadPool>
#include <QTimer>

namespace OCC
{

Q_LOGGING_CATEGORY(lcSyncFolderRemoval, "nextcloud.gui.syncfolderremoval", QtInfoMsg)

namespace SyncFolderRemoval
{

bool isFullySynced(const Folder *folder)
{
    const auto result = folder->syncResult();
    return !folder->isSyncRunning() && !folder->syncPaused() && result.status() == SyncResult::Success && result.numErrorItems() == 0;
}

bool isSafeToDelete(const QString &path)
{
    const auto target = QFileInfo(path).canonicalFilePath();
    if (target.isEmpty()) {
        return false;
    }
    const auto home = QDir(QDir::homePath()).canonicalPath();
    const QString homeWithSlash = home + QLatin1Char('/');
    if (target == home || homeWithSlash.startsWith(target + QLatin1Char('/'))) {
        return false;
    }
    return target.count(QLatin1Char('/')) >= 2;
}

QString bulletList(const QStringList &paths)
{
    QStringList lines;
    for (const auto &path : paths) {
        lines.append(QStringLiteral("• ") + QDir::toNativeSeparators(path));
    }
    return lines.join(QLatin1Char('\n'));
}

void deleteLocalCopies(const QStringList &paths)
{
    // A folder whose sync was running when its connection was removed first finishes aborting.
    QTimer::singleShot(2000, qApp, [paths] {
        for (const auto &path : paths) {
            if (FolderMan::instance()->folderForPath(path)) {
                qCWarning(lcSyncFolderRemoval) << "Not deleting" << path << "- a sync folder still uses it";
                continue;
            }
            // A signed-out account's folder is locked; nothing inside it can be deleted until then.
            FolderLock::unlock(path);
            if (!isSafeToDelete(path)) {
                qCWarning(lcSyncFolderRemoval) << "Not deleting" << path;
                continue;
            }
            const auto target = QFileInfo(path).canonicalFilePath();
            QThreadPool::globalInstance()->start([target] {
                if (QDir(target).removeRecursively()) {
                    qCInfo(lcSyncFolderRemoval) << "Deleted the local copy" << target;
                } else {
                    qCWarning(lcSyncFolderRemoval) << "Could not fully delete" << target;
                }
            });
        }
    });
}

}

}
