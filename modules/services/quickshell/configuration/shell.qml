// shell.qml
import Quickshell
import Quickshell.Io
import QtQuick
import "."


ShellRoot {
    id: root

    property bool searchOpen: false
    property string pendingShellCommand: ""
    property string pendingDesktopId: ""
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

    Process {
        id: runShellProcess
        command: ["sh", "-lc", root.pendingShellCommand]
    }

    Process {
        id: launchDesktopProcess
        command: ["gtk-launch", root.pendingDesktopId]
    }

    Process {
        id: openLauncherProcess
        command: ["wofi", "--show", "drun"]
    }

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

        onCloseRequested: root.searchOpen = false

        onExecuteCommandRequested: function (command) {
            if (!command || command.trim().length === 0) {
                root.searchOpen = false
                return
            }
            root.pendingShellCommand = command
            runShellProcess.running = true
            root.searchOpen = false
        }

        onLaunchDesktopRequested: function (desktopId) {
            if (!desktopId || desktopId.trim().length === 0) {
                root.searchOpen = false
                return
            }
            root.pendingDesktopId = desktopId
            launchDesktopProcess.running = true
            root.searchOpen = false
        }

        onOpenLauncherRequested: function (query) {
            openLauncherProcess.running = true
            root.searchOpen = false
        }
    }
}