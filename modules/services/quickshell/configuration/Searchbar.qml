// Searchbar.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: searchWindow
    
    property var theme
    property bool searchOpen
    
    signal closeRequested()

    // FIX: Anchor bottom AND horizontalCenter to lock it in the center-bottom!
    anchors { bottom: true }
    margins { bottom: 20 } 
    visible: searchOpen 

    implicitHeight: searchLayout.implicitHeight + 20
    
    // ADJUSTED: Changed from 500 to 600 for a wider "half-screen" feel
    implicitWidth: 600 
    
    color: theme.bg || "#1a1b26"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onVisibleChanged: {
        if (visible) {
            searchWindow.requestActivate()
            searchInput.forceActiveFocus()
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: searchWindow.closeRequested()
    }

    ColumnLayout {
        id: searchLayout
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
        spacing: 10

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 45
            color: theme.programBg || "#16161e"
            border.width: 2; border.color: searchInput.focus ? theme.primary : "transparent"

            TextInput {
                id: searchInput
                anchors.fill: parent; anchors.margins: 12
                
                focus: true 
                verticalAlignment: TextInput.AlignVCenter
                color: theme.fg; font.pixelSize: 16; selectByMouse: true

                onVisibleChanged: {
                    if (visible) forceActiveFocus()
                    else text = "" 
                }
                
                onActiveFocusChanged: {
                    if (!activeFocus && searchWindow.visible) {
                        searchWindow.closeRequested() 
                    }
                }
                
                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: "Search apps, files, or commands..."
                    color: theme.danger || "#f7768e" 
                    visible: !searchInput.text && !searchInput.focus
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            property int targetHeight: searchInput.text.length > 0 ? 200 : 0
            Layout.preferredHeight: targetHeight
            visible: searchInput.text.length > 0
            color: "transparent"; clip: true 
            Behavior on targetHeight { NumberAnimation { duration: 200 } }

            Text { 
                anchors.centerIn: parent; 
                text: "Searching system for: " + searchInput.text; 
                color: theme.primary; 
                font.bold: true 
            }
        }
    }
}