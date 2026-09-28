/*
 * SPDX-FileCopyrightText: 2018 Nextcloud GmbH and Nextcloud contributors
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "legalnotice.h"
#include "ui_legalnotice.h"
#include "theme.h"

namespace OCC {


LegalNotice::LegalNotice(QWidget *parent)
    : QDialog(parent)
    , _ui(new Ui::LegalNotice)
{
    _ui->setupUi(this);
    setWindowTitle({});

    connect(_ui->closeButton, &QPushButton::clicked, this, &LegalNotice::accept);

    customizeStyle();
}

LegalNotice::~LegalNotice()
{
    delete _ui;
}

void LegalNotice::changeEvent(QEvent *e)
{
    switch (e->type()) {
    case QEvent::StyleChange:
    case QEvent::PaletteChange:
    case QEvent::ThemeChange:
        customizeStyle();
        break;
    default:
        break;
    }

    QDialog::changeEvent(e);
}

void LegalNotice::customizeStyle()
{
    // The upstream copyright lines stay as they are: the GPL keeps them in every derived work,
    // and the modification notice below is what section 2(a) asks a modified version to carry.
    QString notice = tr("<p>Copyright 2017-2026 Nextcloud GmbH<br />"
                        "Copyright 2012-2023 ownCloud GmbH</p>");

    //: %1 is the name of this build, for example "DataDrive". The sentence tells the user that
    //: this is a modified version of the upstream Nextcloud desktop client, which the GPL
    //: requires a derived work to state.
    notice += tr("<p>%1 is a modified version of the Nextcloud desktop client, "
                 "distributed by its own publisher and not by Nextcloud GmbH.</p>")
                  .arg(Theme::instance()->appNameGUI());

    notice += tr("<p>Licensed under the GNU General Public License (GPL) Version 2.0 or any later version.</p>");

    notice += "<p>&nbsp;</p>";
    notice += Theme::instance()->aboutDetails();

    Theme::replaceLinkColorStringBackgroundAware(notice);

    _ui->notice->setTextInteractionFlags(Qt::TextSelectableByMouse | Qt::TextBrowserInteraction);
    _ui->notice->setText(notice);
    _ui->notice->setWordWrap(true);
    _ui->notice->setOpenExternalLinks(true);
}

} // namespace OCC
