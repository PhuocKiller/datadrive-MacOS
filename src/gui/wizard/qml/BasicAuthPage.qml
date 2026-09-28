/*
 * SPDX-FileCopyrightText: 2026 Nextcloud GmbH and Nextcloud contributors
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import Style
import "../../tray"

Item {
    id: root

    required property var controller
    readonly property color primaryTextColor: Style.wizardPrimaryText
    readonly property color hintTextColor: Style.wizardSecondaryText

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 24
        anchors.bottomMargin: 24
        spacing: 12

        EnforcedPlainTextLabel {
            text: root.controller.publicShareSetup ? qsTr("Connect public share") : qsTr("Enter credentials")
            color: root.primaryTextColor
            font.pixelSize: Style.pixelSize + 8
            font.bold: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        EnforcedPlainTextLabel {
            text: root.controller.publicShareSetup
                ? qsTr("Enter the share password if the link is password protected.")
                : qsTr("Enter the username and password for this server.")
            color: root.hintTextColor
            font.pixelSize: Style.pixelSize + 2
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        WizardTextField {
            Layout.fillWidth: true
            Layout.topMargin: 10
            text: root.controller.basicAuthUser
            enabled: !root.controller.busy
            placeholderText: qsTr("Username")
            selectByMouse: true
            onTextEdited: root.controller.basicAuthUser = text
            onAccepted: root.controller.submitBasicAuth()
        }

        WizardTextField {
            id: passwordField

            property bool passwordShown: false

            Layout.fillWidth: true
            rightPadding: showPasswordButton.width + 8
            text: root.controller.basicAuthPassword
            enabled: !root.controller.busy
            placeholderText: qsTr("Password")
            echoMode: passwordShown ? TextInput.Normal : TextInput.Password
            selectByMouse: true
            onTextEdited: root.controller.basicAuthPassword = text
            onAccepted: root.controller.submitBasicAuth()

            // Shows the password while typing, to catch typos
            Item {
                id: showPasswordButton

                width: 36
                height: parent.height
                anchors.right: parent.right
                anchors.rightMargin: 4
                Accessible.role: Accessible.Button
                Accessible.name: passwordField.passwordShown ? qsTr("Hide password") : qsTr("Show password")

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    sourceSize.width: 18
                    sourceSize.height: 18
                    source: "image://svgimage-custom-color/" + (passwordField.passwordShown ? "eye-off.svg" : "eye.svg")
                        + "/" + (showPasswordMouseArea.containsMouse ? root.primaryTextColor : root.hintTextColor)
                    opacity: passwordField.enabled ? 1 : 0.45
                }

                MouseArea {
                    id: showPasswordMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: passwordField.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: passwordField.passwordShown = !passwordField.passwordShown
                }
            }
        }

        EnforcedPlainTextLabel {
            visible: root.controller.errorText !== ""
            text: root.controller.errorText
            color: Style.wizardErrorText
            font.pixelSize: Style.pixelSize + 1
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            visible: root.controller.busy && root.controller.authStatusText !== ""
            Layout.fillWidth: true
            spacing: 8

            NCBusyIndicator {
                running: root.controller.busy
                visible: running
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
            }

            EnforcedPlainTextLabel {
                text: root.controller.authStatusText
                color: root.hintTextColor
                font.pixelSize: Style.pixelSize + 1
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
