/*
 * SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <functional>

namespace OCC::Mac
{

/**
 * The client lives in the menu bar (LSUIElement), so opening it from Finder, the Dock or Launchpad
 * used to do nothing visible: no window on launch, and the reopen event of a second click was
 * ignored. This calls @p showWindow when the user launches the app, but not when macOS starts it
 * as a login item, and every time the user opens it again while it runs.
 *
 * Call it before the event loop starts, so the launch notification has not been sent yet.
 */
void installLaunchHandlers(std::function<void()> showWindow);

}
