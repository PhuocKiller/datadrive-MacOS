/*
 * SPDX-FileCopyrightText: 2017 Nextcloud GmbH and Nextcloud contributors
 * SPDX-FileCopyrightText: 2015 ownCloud GmbH
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "creds/httpcredentialsgui.h"
#include "account.h"
#include "common/asserts.h"
#include "config.h"
#include "networkjobs.h"
#include "owncloudgui.h"
#include "theme.h"
#include <QBuffer>
#include <QDesktopServices>
#include <QInputDialog>
#include <QLabel>
#include <QMessageBox>
#include <QNetworkReply>
#include <QTimer>

using namespace QKeychain;

namespace OCC {

Q_LOGGING_CATEGORY(lcHttpCredentialsGui, "nextcloud.sync.credentials.http.gui", QtInfoMsg)

void HttpCredentialsGui::askFromUser()
{
    // This function can be called from AccountState::slotInvalidCredentials,
    // which (indirectly, through HttpCredentials::invalidateToken) schedules
    // a cache wipe of the qnam. We can only execute a network job again once
    // the cache has been cleared, otherwise we'd interfere with the job.
    QTimer::singleShot(100, this, &HttpCredentialsGui::askFromUserAsync);
}

void HttpCredentialsGui::askFromUserAsync()
{
#if APPLICATION_FORCE_IN_APP_LOGIN
    // This build signs in with a password typed into the client, and its wizard never asks the
    // server how (see Theme). The server answers LoginFlowV2 from version 16 on, which the branch
    // below turned into a silent failure: after logging out, logging in again showed nothing and
    // the account went straight back to "Signed out".
    showDialog();
    return;
#endif

    // First, we will check what kind of auth we need.
    auto job = new DetermineAuthTypeJob(_account->sharedFromThis(), this);
    QObject::connect(job, &DetermineAuthTypeJob::authType, this, [this](DetermineAuthTypeJob::AuthType type) {
        if (type == DetermineAuthTypeJob::Basic) {
            showDialog();
        } else {
            // Shibboleth?
            qCWarning(lcHttpCredentialsGui) << "Bad http auth type:" << type;
            Q_EMIT asked();
        }
    });
    job->start();
}

void HttpCredentialsGui::showDialog()
{
    QString msg = tr("Please enter %1 password:<br>"
                     "<br>"
                     "Username: %2<br>"
                     "Account: %3<br>")
                      .arg(Utility::escape(Theme::instance()->appNameGUI()),
                          Utility::escape(_user),
                          Utility::escape(_account->displayName()));

    QString reqTxt = requestAppPasswordText(_account);
    if (!reqTxt.isEmpty()) {
        msg += QLatin1String("<br>") + reqTxt + QLatin1String("<br>");
    }
    if (!_fetchErrorString.isEmpty()) {
        msg += QLatin1String("<br>")
            + tr("Reading from keychain failed with error: \"%1\"")
                  .arg(Utility::escape(_fetchErrorString))
            + QLatin1String("<br>");
    }

    auto *dialog = new QInputDialog();
    dialog->setAttribute(Qt::WA_DeleteOnClose, true);
    dialog->setWindowTitle(tr("Enter Password"));
    dialog->setLabelText(msg);
    dialog->setTextValue(_previousPassword);
    dialog->setTextEchoMode(QLineEdit::Password);
    if (auto *dialogLabel = dialog->findChild<QLabel *>()) {
        dialogLabel->setOpenExternalLinks(true);
        dialogLabel->setTextFormat(Qt::RichText);
    }

    // The Log in button sits in the settings window, which covered the dialog: raising alone does
    // not bring a parentless dialog of a menu bar app in front of it.
    dialog->setWindowFlag(Qt::WindowStaysOnTopHint);
    dialog->open();
    ownCloudGui::raiseDialog(dialog);
    connect(dialog, &QDialog::finished, this, [this, dialog](int result) {
        if (result == QDialog::Accepted) {
            _password = dialog->textValue();
            _ready = true;
            persist();
        }
        Q_EMIT asked();
    });
}

QString HttpCredentialsGui::requestAppPasswordText(const Account *account)
{
    int version = account->serverVersionInt();
    auto url = account->url().toString();
    if (url.endsWith('/')) {
        url.chop(1);
    }

    if (version >= Account::makeServerVersion(13, 0, 0)) {
        url += QLatin1String("/index.php/settings/user/security");
    } else if (version >= Account::makeServerVersion(12, 0, 0)) {
        url += QLatin1String("/index.php/settings/personal#security");
    } else if (version >= Account::makeServerVersion(11, 0, 0)) {
        url += QLatin1String("/index.php/settings/user/security#security");
    } else {
        return QString();
    }

    return tr("<a href=\"%1\">Click here</a> to request an app password from the web interface.")
        .arg(url);
}
} // namespace OCC
