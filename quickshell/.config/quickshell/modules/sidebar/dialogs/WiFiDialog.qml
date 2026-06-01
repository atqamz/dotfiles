import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services

Rectangle {
    id: root

    signal dismiss()

    // SSID of the secured network awaiting a password, or "" when none.
    property string pendingSsid: ""

    color: Theme.surfaceContainerHigh
    radius: Theme.radius.large
    border.color: Theme.outlineVariant
    border.width: 1

    implicitHeight: dialogCol.implicitHeight + 24

    Component.onCompleted: Network.scanWifi()

    // Keep the list fresh while the panel is open.
    Timer {
        interval: 10000
        running: Network.wifiEnabled
        repeat: true
        onTriggered: Network.scanWifi()
    }

    // After a radio flip / connect / disconnect, nudge a state+list refresh a
    // couple times so the switch and the active row update without waiting for
    // the global 5s poll.
    Timer {
        id: repoll
        interval: 1300
        repeat: true
        triggeredOnStart: false
        property int ticks: 0
        onTriggered: {
            Network.poll();
            if (++ticks >= 2) { ticks = 0; stop(); }
        }
        function kick() { ticks = 0; restart(); }
    }

    ColumnLayout {
        id: dialogCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.normal

            StyledText {
                text: "Wi-Fi"
                font.pixelSize: Theme.font.size.large
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Item {
                property real radius: Theme.radius.small
                implicitWidth: refreshIcon.implicitWidth + 2 * Theme.padding.smaller
                implicitHeight: refreshIcon.implicitHeight + 2 * Theme.padding.smaller
                opacity: Network.wifiEnabled ? 1 : 0.4

                StateLayer { pressed: refreshMa.pressed }

                MaterialIcon {
                    id: refreshIcon
                    anchors.centerIn: parent
                    text: "refresh"
                    color: Network.scanning ? Theme.tertiary : Theme.textVariant
                    font.pixelSize: Theme.icon.size.small

                    RotationAnimation on rotation {
                        running: Network.scanning
                        from: 0; to: 360
                        duration: Theme.anim.durations.spring
                        easing.type: Easing.Linear
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: refreshMa
                    anchors.fill: parent
                    enabled: Network.wifiEnabled
                    onClicked: Network.scanWifi()
                }
            }

            StyledSwitch {
                id: radioSwitch
                checked: Network.wifiEnabled
                onToggled: {
                    Network.setWifiRadio(checked);
                    repoll.kick();
                }
            }

            IconButton {
                icon: "close"
                onClicked: root.dismiss()
            }
        }

        Connections {
            target: Network
            function onWifiEnabledChanged() { radioSwitch.checked = Network.wifiEnabled; }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
        }

        // Radio off: list is meaningless, show a single prompt instead.
        StyledText {
            visible: !Network.wifiEnabled
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.small
            Layout.bottomMargin: Theme.spacing.small
            horizontalAlignment: Text.AlignHCenter
            text: "Wi-Fi is off"
            color: Theme.textMuted
        }

        Repeater {
            model: Network.wifiEnabled ? Network.wifiNetworks : []

            ColumnLayout {
                id: netEntry
                required property var modelData
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    id: netRow
                    Layout.fillWidth: true
                    height: 40
                    radius: Theme.radius.normal
                    color: netEntry.modelData.active ? Theme.surfaceContainerHighest : "transparent"

                    StateLayer {
                        pressed: netMa.pressed
                        focused: netEntry.modelData.active
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding.normal
                        anchors.rightMargin: Theme.padding.normal
                        spacing: Theme.spacing.normal

                        // Only signal_wifi_4_bar exists in Material Icons Round
                        // (no graded bars), so convey strength via opacity.
                        MaterialIcon {
                            text: "wifi"
                            color: netEntry.modelData.active ? Theme.tertiary : Theme.textVariant
                            opacity: 0.4 + 0.6 * Math.min(1, netEntry.modelData.signal / 100)
                            font.pixelSize: Theme.icon.size.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: netEntry.modelData.ssid
                            color: Theme.text
                            elide: Text.ElideRight
                        }

                        MaterialIcon {
                            visible: netEntry.modelData.security.length > 0
                            text: "lock"
                            color: Theme.textMuted
                            font.pixelSize: Theme.icon.size.small
                        }

                        // Connected networks show a disconnect affordance; others
                        // a check only when active (which can't co-occur, kept simple).
                        MaterialIcon {
                            visible: netEntry.modelData.active
                            text: "link_off"
                            color: Theme.tertiary
                            font.pixelSize: Theme.icon.size.small
                        }
                    }

                    MouseArea {
                        id: netMa
                        anchors.fill: parent
                        onClicked: {
                            const ssid = netEntry.modelData.ssid;
                            if (netEntry.modelData.active) {
                                Network.disconnectWifi(ssid);
                                root.pendingSsid = "";
                                repoll.kick();
                            } else if (netEntry.modelData.security.length > 0 && !Network.isSaved(ssid)) {
                                // Unknown secured network: ask for a password.
                                root.pendingSsid = root.pendingSsid === ssid ? "" : ssid;
                            } else {
                                // Open, or a saved profile: nmcli reuses stored creds.
                                Network.connectWifi(ssid, "");
                                root.pendingSsid = "";
                                repoll.kick();
                            }
                        }
                    }
                }

                // Inline password prompt for the tapped secured network.
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.padding.normal
                    Layout.rightMargin: Theme.padding.normal
                    visible: root.pendingSsid === netEntry.modelData.ssid
                    spacing: Theme.spacing.small

                    TextField {
                        id: pwField
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        placeholderText: "Password"
                        color: Theme.text
                        placeholderTextColor: Theme.textMuted
                        renderType: Text.NativeRendering
                        font.family: Theme.font.family.sans
                        font.pixelSize: Theme.font.size.normal
                        onVisibleChanged: if (visible) forceActiveFocus()

                        background: Rectangle {
                            radius: Theme.radius.small
                            color: Theme.surfaceContainerHighest
                            border.width: 1
                            border.color: pwField.activeFocus ? Theme.primary : Theme.outline
                            Behavior on border.color { CAnim {} }
                        }

                        function submit() {
                            if (text.length === 0) return;
                            Network.connectWifi(netEntry.modelData.ssid, text);
                            text = "";
                            root.pendingSsid = "";
                            repoll.kick();
                        }
                        Keys.onReturnPressed: submit()
                        Keys.onEscapePressed: root.pendingSsid = ""
                    }

                    Rectangle {
                        width: 36; height: 36; radius: Theme.radius.full
                        color: pwField.text.length > 0 ? Theme.primary : Theme.surfaceContainerHigh

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "arrow_forward"
                            color: pwField.text.length > 0 ? Theme.textOnPrimary : Theme.textMuted
                            font.pixelSize: Theme.icon.size.small
                        }

                        StateLayer {
                            pressed: pwSubmit.pressed
                            tint: pwField.text.length > 0 ? Theme.textOnPrimary : Theme.text
                        }

                        MouseArea {
                            id: pwSubmit
                            anchors.fill: parent
                            onClicked: pwField.submit()
                        }
                    }
                }
            }
        }

        StyledText {
            visible: Network.wifiEnabled && Network.wifiNetworks.length === 0
            Layout.alignment: Qt.AlignHCenter
            text: Network.scanning ? "Scanning..." : "No networks found"
            color: Theme.textMuted
        }
    }
}
