/*
 * SPDX-FileCopyrightText: 2021 Nextcloud GmbH and Nextcloud contributors
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <QTest>

#include "theme.h"
#include "themeutils.h"
#include "iconutils.h"
#include "logger.h"

#include <QStandardPaths>

class TestTheme : public QObject
{
    Q_OBJECT

public:
    TestTheme()
    {
        Q_INIT_RESOURCE(resources);
        Q_INIT_RESOURCE(theme);
    }

private Q_SLOTS:
    void initTestCase()
    {
        OCC::Logger::instance()->setLogFlush(true);
        OCC::Logger::instance()->setLogDebug(true);

        QStandardPaths::setTestModeEnabled(true);
    }

    void testHidpiFileName_darkBackground_returnPathToWhiteIcon()
    {
        FakePaintDevice paintDevice;
        const QColor backgroundColor("#000000");
        const QString iconName("icon-name");

        const auto iconPath = OCC::Theme::hidpiFileName(iconName + ".png", backgroundColor, &paintDevice);

        QCOMPARE(iconPath, ":/client/theme/white/" + iconName + ".png");
    }

    void testHidpiFileName_lightBackground_returnPathToBlackIcon()
    {
        FakePaintDevice paintDevice;
        const QColor backgroundColor("#ffffff");
        const QString iconName("icon-name");

        const auto iconPath = OCC::Theme::hidpiFileName(iconName + ".png", backgroundColor, &paintDevice);

        QCOMPARE(iconPath, ":/client/theme/black/" + iconName + ".png");
    }

    void testHidpiFileName_hidpiDevice_returnHidpiIconPath()
    {
        FakePaintDevice paintDevice;
        paintDevice.setHidpi(true);
        const QColor backgroundColor("#000000");
        const QString iconName("wizard-files");

        const auto iconPath = OCC::Theme::hidpiFileName(iconName + ".png", backgroundColor, &paintDevice);

        QCOMPARE(iconPath, ":/client/theme/white/" + iconName + "@2x.png");
    }

    void testIsDarkColor_nextcloudBlue_returnTrue()
    {
        const QColor color(0, 130, 201);

        const auto result = OCC::Theme::isDarkColor(color);

        QCOMPARE(result, true);
    }

    void testIsDarkColor_lightColor_returnFalse()
    {
        const QColor color(255, 255, 255);

        const auto result = OCC::Theme::isDarkColor(color);

        QCOMPARE(result, false);
    }

    void testIsDarkColor_darkColor_returnTrue()
    {
        const QColor color(0, 0, 0);

        const auto result = OCC::Theme::isDarkColor(color);

        QCOMPARE(result, true);
    }

    void testIsHidpi_hidpi_returnTrue()
    {
        FakePaintDevice paintDevice;
        paintDevice.setHidpi(true);

        QCOMPARE(OCC::Theme::isHidpi(&paintDevice), true);
    }

    void testIsHidpi_lowdpi_returnFalse()
    {
        FakePaintDevice paintDevice;
        paintDevice.setHidpi(false);

        QCOMPARE(OCC::Theme::isHidpi(&paintDevice), false);
    }

    void brandedServerUrlIsEnforcedAndStartsTheLoginFlow()
    {
        const auto theme = OCC::Theme::instance();

#if defined(APPLICATION_SERVER_URL) && defined(APPLICATION_SERVER_URL_ENFORCE)
        QCOMPARE(theme->overrideServerUrl(), QString::fromUtf8(APPLICATION_SERVER_URL));
        QVERIFY(theme->forceOverrideServerUrl());
        // With nothing left to ask on the server page the wizard must open on the login step.
        QVERIFY(theme->startLoginFlowAutomatically());
#else
        QVERIFY(theme->overrideServerUrl().isEmpty());
        QVERIFY(!theme->startLoginFlowAutomatically());
#endif
    }

    void homepageUrlMatchesTheBrandingDefine()
    {
        const auto homepageUrl = OCC::Theme::instance()->homepageUrl();

#ifdef APPLICATION_HOMEPAGE_URL
        QCOMPARE(homepageUrl, QString::fromUtf8(APPLICATION_HOMEPAGE_URL));
        // A button is only worth showing for an address the browser can actually open.
        const QUrl parsedHomepageUrl{homepageUrl};
        QVERIFY(parsedHomepageUrl.isValid());
        QVERIFY(!parsedHomepageUrl.host().isEmpty());
        QVERIFY(parsedHomepageUrl.scheme() == QStringLiteral("https"));
#else
        QVERIFY(homepageUrl.isEmpty());
#endif
    }

    void homepageUrlIsADifferentHostThanTheServer()
    {
#if defined(APPLICATION_HOMEPAGE_URL) && defined(APPLICATION_SERVER_URL)
        const auto theme = OCC::Theme::instance();
        // The button exists to send users to the public website rather than the sync server, so
        // pointing both at one host would make it pointless.
        QVERIFY(QUrl(theme->homepageUrl()).host() != QUrl(theme->overrideServerUrl()).host());
#else
        QSKIP("Build defines no branded homepage and server URL pair.");
#endif
    }

    void forceInAppLoginMatchesTheBrandingDefine()
    {
#if APPLICATION_FORCE_IN_APP_LOGIN
        QVERIFY(OCC::Theme::instance()->forceInAppLogin());
#else
        QVERIFY(!OCC::Theme::instance()->forceInAppLogin());
#endif
    }
};

QTEST_GUILESS_MAIN(TestTheme)
#include "testtheme.moc"
