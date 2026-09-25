/*
 * SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "uninstaller.h"

#include "accountmanager.h"
#include "common/utility.h"
#include "config.h"
#include "configfile.h"
#include "folderlock.h"
#include "folderman.h"
#include "syncfolderremoval.h"
#include "theme.h"

#ifdef BUILD_FILE_PROVIDER_MODULE
#include "macOS/fileprovider.h"
#endif

#include <QApplication>
#include <QDir>
#include <QFileInfo>
#include <QLoggingCategory>
#include <QMessageBox>
#include <QProcess>
#include <QPushButton>
#include <QStandardPaths>
#include <QTimer>

namespace OCC
{

Q_LOGGING_CATEGORY(lcUninstaller, "nextcloud.gui.uninstaller", QtInfoMsg)

namespace
{

/// Waits for the client to exit, deletes the given paths, then moves the app bundle to the Trash.
/// Arguments: pid, app bundle ("" for none), keychain service, then the paths to delete.
///
/// Before the app goes, its extensions are unregistered and their sandbox containers deleted (macOS
/// may refuse to delete the container folders themselves), its defaults are removed, and
/// every keychain item of the service is removed: the account setup stores the password once
/// before the account has an id, and removing the account only deletes the entry that has one.
const auto helperScript = QStringLiteral(R"sh(pid=$1; app=$2; service=$3; shift 3
while kill -0 "$pid" 2>/dev/null; do sleep 0.5; done
for target in "$@"; do chmod u+rwx -- "$target" 2>/dev/null; rm -rf -- "$target"; done
while security delete-generic-password -s "$service" >/dev/null 2>&1; do :; done
if [ -n "$app" ] && [ -d "$app" ]; then
    for bundle in "$app"/Contents/PlugIns/*.appex "$app"/Contents/Library/LoginItems/*.app; do
        [ -d "$bundle" ] || continue
        id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$bundle/Contents/Info.plist" 2>/dev/null)
        pluginkit -r "$bundle" 2>/dev/null
        [ -n "$id" ] && rm -rf -- "$HOME/Library/Containers/$id"
    done
    appId=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null)
    [ -n "$appId" ] && defaults delete "$appId" 2>/dev/null
    mv -- "$app" "$HOME/.Trash/$(basename "$app" .app) $(date '+%Y-%m-%d %H.%M.%S').app"
fi
)sh");
}

QString Uninstaller::actionText()
{
    return tr("Uninstall %1…").arg(Theme::instance()->appNameGUI());
}

void Uninstaller::confirmAndRun(QWidget *parent)
{
    const auto appName = Theme::instance()->appNameGUI();
    const auto folders = FolderMan::instance()->map().values();

    QStringList localFolders;
    QStringList notSynced;
    for (const auto folder : folders) {
        localFolders.append(folder->path());
        if (!SyncFolderRemoval::isFullySynced(folder)) {
            notSynced.append(folder->path());
        }
    }

    auto details = localFolders.isEmpty() ? tr("This removes your accounts, the saved password and the settings of %1 from this computer.").arg(appName)
                                          : tr("This removes your accounts, the saved password and the settings of %1 from this computer, "
                                               "and deletes the local copies of your synced folders:\n\n%2")
                                                .arg(appName, SyncFolderRemoval::bulletList(localFolders));
    details += QStringLiteral("\n\n") + tr("Your files stay on the server.");
    if (!notSynced.isEmpty()) {
        details += QStringLiteral("\n\n")
            + tr("These folders are not fully synced right now. Anything in them that has not "
                 "reached the server yet will be lost:\n\n%1")
                  .arg(SyncFolderRemoval::bulletList(notSynced));
    }

    QMessageBox box(parent);
    box.setIcon(notSynced.isEmpty() ? QMessageBox::Question : QMessageBox::Warning);
    box.setWindowTitle(tr("Uninstall %1").arg(appName));
    box.setText(tr("Remove %1 from this computer?").arg(appName));
    box.setInformativeText(details);
    const auto uninstallButton = box.addButton(tr("Uninstall"), QMessageBox::DestructiveRole);
    box.setDefaultButton(box.addButton(QMessageBox::Cancel));
    box.exec();

    if (box.clickedButton() != uninstallButton) {
        return;
    }
    run(localFolders);
}

void Uninstaller::run(const QStringList &localFolders)
{
    qCInfo(lcUninstaller) << "Uninstalling, local folders:" << localFolders;

    // 1. Stop syncing before anything is deleted, so no deletion can reach the server.
    const auto folderMan = FolderMan::instance();
    const auto folders = folderMan->map().values();
    for (const auto folder : folders) {
        // A signed-out account's folder is locked, and the helper below could not delete it.
        FolderLock::unlock(folder->path());
        folderMan->removeFolder(folder);
    }

    // 2. Accounts: revokes the app password on the server, forgets the keychain entries.
    const auto accountManager = AccountManager::instance();
    for (const auto &account : accountManager->accounts()) {
        accountManager->deleteAccount(account.data());
    }
    accountManager->save();

#ifdef BUILD_FILE_PROVIDER_MODULE
    // Virtual files live in File Provider domains that macOS manages; removing the domains makes the
    // system delete their local copies as well. Asynchronous, covered by the delay before quitting.
    if (const auto fileProvider = Mac::FileProvider::instance()) {
        if (const auto domainManager = fileProvider->domainManager()) {
            domainManager->removeAllDomains();
        }
    }
#endif

    Utility::setLaunchOnStartup(Theme::instance()->appName(), Theme::instance()->appNameGUI(), false);

    // 3. Files are deleted by a helper once this process is gone.
    QStringList targets;
    auto candidates = QStringList{localFolders} << ConfigFile().configPath() << QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                                                << QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
#if defined(Q_OS_MACOS) && defined(DEVELOPMENT_TEAM)
    // Shared with the extensions: File Provider domain data, the socket and their logs.
    candidates << QDir::homePath() + QStringLiteral("/Library/Group Containers/" DEVELOPMENT_TEAM "." APPLICATION_REV_DOMAIN);
#endif
    for (const auto &path : candidates) {
        if (SyncFolderRemoval::isSafeToDelete(path)) {
            targets.append(QFileInfo(path).canonicalFilePath());
        } else {
            qCWarning(lcUninstaller) << "Not deleting" << path;
        }
    }

    auto appBundle = QDir(QCoreApplication::applicationDirPath() + QStringLiteral("/../..")).canonicalPath();
    if (!appBundle.endsWith(QStringLiteral(".app"))) {
        appBundle.clear();
    }

    const auto arguments = QStringList{QStringLiteral("-c"),
                                       helperScript,
                                       QStringLiteral("uninstall"),
                                       QString::number(QCoreApplication::applicationPid()),
                                       appBundle,
                                       Theme::instance()->appName()}
        + targets;
    if (!QProcess::startDetached(QStringLiteral("/bin/sh"), arguments)) {
        qCWarning(lcUninstaller) << "Could not start the cleanup helper; files are left in place";
    }

    // The keychain deletions and the app password revocation run asynchronously.
    QTimer::singleShot(3000, qApp, &QCoreApplication::quit);
}

}
