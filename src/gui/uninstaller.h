/*
 * SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <QCoreApplication>
#include <QString>
#include <QStringList>

class QWidget;

namespace OCC
{

/**
 * Removes the client from this computer: the sync connections, the accounts with their saved
 * credentials, the local copies of the synced folders, the settings, the caches and the app bundle.
 *
 * Files on the server are never touched. Every sync connection is removed first, and the local
 * folders are only deleted by a helper process after this process has exited, so no sync run can
 * notice the deletions and propagate them to the server.
 *
 * macOS gives an app no chance to clean up when it is dragged to the Trash, which is why this is a
 * menu action there. On Windows the uninstaller does the same job.
 */
class Uninstaller
{
    Q_DECLARE_TR_FUNCTIONS(Uninstaller)

public:
    /// Menu entry text, e.g. "Uninstall DataDrive…".
    [[nodiscard]] static QString actionText();

    /// Shows what is going to be deleted, warns about folders that are not fully synced, and on
    /// confirmation uninstalls and quits. Nothing happens if the user cancels.
    static void confirmAndRun(QWidget *parent = nullptr);

private:
    static void run(const QStringList &localFolders);
};

}
