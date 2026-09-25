/*
 * SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "launchhandler_mac.h"

#include <QLoggingCategory>

#import <AppKit/AppKit.h>

Q_LOGGING_CATEGORY(lcLaunchHandler, "nextcloud.gui.launchhandler", QtInfoMsg)

@interface DataDriveLaunchHandler : NSObject {
@public
    std::function<void()> _showWindow;
}
@end

@implementation DataDriveLaunchHandler

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    Q_UNUSED(notification)
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];

    // While the launch notification is delivered, the current Apple event is the one that
    // opened the app; a login item launch marks it with keyAELaunchedAsLogInItem.
    NSAppleEventDescriptor *const launchEvent = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    const BOOL launchedAtLogin =
        launchEvent.eventID == kAEOpenApplication && [launchEvent paramDescriptorForKeyword:keyAEPropData].enumCodeValue == keyAELaunchedAsLogInItem;
    qCInfo(lcLaunchHandler) << "Launched" << (launchedAtLogin ? "as a login item" : "by the user");
    if (!launchedAtLogin && _showWindow) {
        _showWindow();
    }
}

- (void)handleReopenEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)reply
{
    Q_UNUSED(event)
    Q_UNUSED(reply)
    qCInfo(lcLaunchHandler) << "Opened again while running";
    if (_showWindow) {
        _showWindow();
    }
}

@end

namespace OCC::Mac
{

void installLaunchHandlers(std::function<void()> showWindow)
{
    // Lives as long as the app, like the handlers registered with it.
    static DataDriveLaunchHandler *const handler = [[DataDriveLaunchHandler alloc] init];
    handler->_showWindow = std::move(showWindow);

    if (![NSRunningApplication currentApplication].finishedLaunching) {
        [[NSNotificationCenter defaultCenter] addObserver:handler
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    } else {
        qCWarning(lcLaunchHandler) << "Installed after launch; the window is only shown on reopen";
    }

    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:handler
                                                       andSelector:@selector(handleReopenEvent:withReplyEvent:)
                                                     forEventClass:kCoreEventClass
                                                        andEventID:kAEReopenApplication];
}

}
