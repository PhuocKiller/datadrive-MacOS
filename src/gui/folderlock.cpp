/*
 * SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "folderlock.h"

#include "configfile.h"

#include <QDir>
#include <QFile>
#include <QLoggingCategory>
#include <QSettings>
#include <QUrl>

#ifdef Q_OS_UNIX
#include <sys/stat.h>
#endif

namespace OCC
{

Q_LOGGING_CATEGORY(lcFolderLock, "nextcloud.gui.folderlock", QtInfoMsg)

namespace FolderLock
{

namespace
{

[[maybe_unused]] QString normalized(const QString &path)
{
    return QDir::cleanPath(path);
}

/// QSettings keys may not contain '/', so the path is percent-encoded.
[[maybe_unused]] QString settingsKey(const QString &path)
{
    return QString::fromLatin1(QUrl::toPercentEncoding(normalized(path)));
}

[[maybe_unused]] std::unique_ptr<QSettings> lockSettings()
{
    return ConfigFile::settingsWithGroup(QStringLiteral("FolderLock"));
}

}

bool lock(const QString &path)
{
#ifdef Q_OS_UNIX
    if (isLocked(path)) {
        return true;
    }

    const auto target = normalized(path);
    const auto nativePath = QFile::encodeName(target);
    struct stat info{};
    if (::stat(nativePath.constData(), &info) != 0 || !S_ISDIR(info.st_mode)) {
        qCWarning(lcFolderLock) << "Not locking" << target << "- not a folder";
        return false;
    }

    // Saved first: if the app dies right after chmod, the next unlock still knows the mode.
    const auto settings = lockSettings();
    settings->setValue(settingsKey(target), static_cast<int>(info.st_mode & 07777));
    settings->sync();

    if (::chmod(nativePath.constData(), 0) != 0) {
        qCWarning(lcFolderLock) << "Could not lock" << target;
        settings->remove(settingsKey(target));
        return false;
    }
    qCInfo(lcFolderLock) << "Locked" << target;
    return true;
#else
    Q_UNUSED(path)
    return false;
#endif
}

bool unlock(const QString &path)
{
#ifdef Q_OS_UNIX
    const auto target = normalized(path);
    const auto settings = lockSettings();
    const auto key = settingsKey(target);
    if (!settings->contains(key)) {
        return false;
    }

    const auto mode = static_cast<mode_t>(settings->value(key).toInt());
    // A mode without owner access would lock the owner out for good; fall back to rwx for the owner.
    const auto restoredMode = (mode & S_IRWXU) == S_IRWXU ? mode : static_cast<mode_t>(mode | S_IRWXU);
    if (::chmod(QFile::encodeName(target).constData(), restoredMode) != 0) {
        qCWarning(lcFolderLock) << "Could not unlock" << target;
        return false;
    }
    settings->remove(key);
    qCInfo(lcFolderLock) << "Unlocked" << target;
    return true;
#else
    Q_UNUSED(path)
    return false;
#endif
}

bool isLocked(const QString &path)
{
#ifdef Q_OS_UNIX
    return lockSettings()->contains(settingsKey(path));
#else
    Q_UNUSED(path)
    return false;
#endif
}

}

}
