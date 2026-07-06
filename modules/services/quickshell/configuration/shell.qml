// shell.qml
import Quickshell
import QtQuick
import "."


ShellRoot {
    id: root

    property bool searchOpen: false
    property var theme: ({
        "bg": "#1a1b26", "fg": "#c0caf5", "primary": "#7aa2f7", "danger": "#f7768e", "programBg": "#16161e"
    })

    function loadColors() {
        var xhr = new XMLHttpRequest();
        var path = "file:///home/" + Quickshell.env("USER") + "/.config/palettes/active.json";
        xhr.open("GET", path, false); xhr.send();
        if (xhr.readyState === XMLHttpRequest.DONE && xhr.responseText !== "") {
            root.theme = JSON.parse(xhr.responseText);
        }
    }

    Component.onCompleted: loadColors()

    // ==========================================
    // 1. INVISIBLE HOVER TRIPWIRE
    // ==========================================
    PanelWindow {
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 5; color: "transparent"
        MouseArea {
            anchors.fill: parent; hoverEnabled: true
            onEntered: root.searchOpen = true
        }
    }

    // ==========================================
    // 2. OUR CUSTOM MODULES!
    // ==========================================
    
    Sidebar {
        theme: root.theme
        searchOpen: root.searchOpen
        
        // Listen for the signal we created in Sidebar.qml!
        onToggleSearchClicked: {
            root.searchOpen = !root.searchOpen
        }
    }

    Searchbar {
        theme: root.theme
        searchOpen: root.searchOpen
        
        // Listen for the signal we created in SearchPopup.qml!
        onCloseRequested: {
            root.searchOpen = false
        }
    }
}