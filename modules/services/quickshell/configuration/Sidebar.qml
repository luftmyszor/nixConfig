// Sidebar.qml
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: sidebar
    
    // Properties given by the parent
    property var theme
    property bool searchOpen
    
    // Signal to tell the parent to close/open the menu
    signal toggleSearchClicked()

    anchors { left: true; top: true; bottom: true }
    implicitWidth: 60
    color: theme.programBg || "#16161e"

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 10; spacing: 15

        // SEARCH TOGGLE BUTTON
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 40; height: 40; radius: 10
            color: searchOpen ? theme.primary : "transparent"
            border.width: 2; border.color: theme.primary

            Text {
                anchors.centerIn: parent
                text: "🔍"
                color: searchOpen ? theme.bg : theme.primary
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: sidebar.toggleSearchClicked() 
            }
        }

        // APP LAUNCHER
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 40; height: 40; radius: 10
            color: "transparent"
            border.width: 2; border.color: theme.primary
            
            Text { anchors.centerIn: parent; text: "⊞"; color: theme.primary; font.pixelSize: 20 }
            
            Process { id: openLauncher; command: ["wofi", "--show", "drun"] }
            
            MouseArea { 
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: openLauncher.running = true 
            }
        }

        Item { Layout.fillHeight: true; Layout.fillWidth: true } // Invisible Spacer

        // VERTICAL CLOCK
        Text {
            id: clockText
            Layout.alignment: Qt.AlignHCenter
            color: theme.fg; font.bold: true; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter
            text: "00\n00" 
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: {
                    var d = new Date();
                    clockText.text = d.getHours().toString().padStart(2, '0') + "\n" + d.getMinutes().toString().padStart(2, '0');
                }
            }
        }

        // POWER BUTTON
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 40; height: 40; radius: 10; color: "transparent"
            Text { anchors.centerIn: parent; text: "⏻"; color: theme.danger; font.pixelSize: 20 }
            
            Process { id: powerSys; command: ["systemctl", "poweroff"] }
            
            MouseArea { 
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor 
                /* onClicked: powerSys.running = true */ 
            }
        }
    }
}