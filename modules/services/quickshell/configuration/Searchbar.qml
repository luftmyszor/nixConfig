// Searchbar.qml
import Quickshell
import Quickshell.Wayland
import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: searchWindow

    property var theme
    property bool searchOpen
    property int overlayPadding: 10
    property int frameRadius: 14
    property var appEntries: []
    property var filteredEntries: []
    property bool commandMode: searchInput.text.length > 0 && searchInput.text.charAt(0) === ">"
    property string commandText: commandMode ? searchInput.text.slice(1).trim() : ""
    property string queryText: commandMode ? "" : searchInput.text.trim().toLowerCase()
    property real maxOverlayHeight: (searchWindow.screen && searchWindow.screen.height > 0) ? searchWindow.screen.height * 0.4 : 432
    property real rawImplicitHeight: contentFrame.implicitHeight

    signal closeRequested()
    signal executeCommandRequested(string command)
    signal launchDesktopRequested(string desktopId)
    signal openLauncherRequested(string query)

    function prettyNameFromDesktopId(desktopId) {
        var cleaned = desktopId.replace(/\.desktop$/i, "");
        cleaned = cleaned.replace(/[-_]/g, " ");
        return cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
    }

    function collectDesktopEntries(model, into, seen) {
        for (var i = 0; i < model.count; i++) {
            var fileName = model.get(i, "fileName");
            if (!fileName || !fileName.endsWith(".desktop") || seen[fileName]) {
                continue;
            }
            seen[fileName] = true;
            into.push({
                "desktopId": fileName,
                "title": prettyNameFromDesktopId(fileName),
                "subtitle": fileName
            });
        }
    }

    function rebuildAppEntries() {
        var entries = [];
        var seen = {};
        collectDesktopEntries(systemDesktopModel, entries, seen);
        collectDesktopEntries(systemProfileDesktopModel, entries, seen);
        collectDesktopEntries(userProfileDesktopModel, entries, seen);
        collectDesktopEntries(homeProfileDesktopModel, entries, seen);
        collectDesktopEntries(userDesktopModel, entries, seen);
        entries.sort(function (a, b) {
            return a.title.localeCompare(b.title);
        });
        appEntries = entries;
        applyFilter();
    }

    function applyFilter() {
        if (!queryText.length) {
            filteredEntries = [];
            return;
        }

        var query = queryText.toLowerCase();
        var matches = [];
        for (var i = 0; i < appEntries.length; i++) {
            var item = appEntries[i];
            if (item.title.toLowerCase().indexOf(query) !== -1 || item.subtitle.toLowerCase().indexOf(query) !== -1) {
                matches.push(item);
            }
            if (matches.length >= 30) {
                break;
            }
        }
        filteredEntries = matches;
    }

    function submitPrimaryAction() {
        if (commandMode) {
            if (commandText.length) {
                executeCommandRequested(commandText);
            }
            closeRequested();
            return;
        }

        if (filteredEntries.length > 0) {
            launchDesktopRequested(filteredEntries[0].desktopId);
        } else if (searchInput.text.trim().length > 0) {
            openLauncherRequested(searchInput.text.trim());
        }
        closeRequested();
    }

    anchors {
        bottom: true
    }
    margins { bottom: 0 }
    visible: searchOpen
    implicitHeight: Math.min(rawImplicitHeight, maxOverlayHeight)
    implicitWidth: 600
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
        if (visible) {
            searchWindow.requestActivate()
            searchInput.forceActiveFocus()
            searchInput.cursorPosition = searchInput.text.length
        } else {
            searchInput.text = ""
        }
    }

    onQueryTextChanged: applyFilter()

    Component.onCompleted: rebuildAppEntries()

    Shortcut {
        sequence: "Escape"
        onActivated: searchWindow.closeRequested()
    }

    Rectangle {
        id: contentFrame
        anchors.fill: parent
        color: theme.bg || "#1a1b26"
        radius: frameRadius
        clip: true
        implicitHeight: contentColumn.implicitHeight + overlayPadding * 2

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 2
            color: theme.primary || "#7aa2f7"
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: theme.primary || "#7aa2f7"
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: theme.primary || "#7aa2f7"
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: frameRadius
            color: theme.bg || "#1a1b26"
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: overlayPadding
            spacing: 10

            Rectangle {
                id: resultsContainer
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                implicitHeight: visible ? Math.min(resultsFlick.contentHeight + 8, Math.max(maxOverlayHeight - 75, 0)) : 0
                visible: searchInput.text.trim().length > 0
                color: "transparent"
                clip: true

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                Flickable {
                    id: resultsFlick
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: resultsColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Column {
                        id: resultsColumn
                        width: resultsFlick.width
                        spacing: 4

                        Repeater {
                            model: commandMode ? 1 : filteredEntries.length

                            delegate: Rectangle {
                                required property int index
                                readonly property var entry: commandMode ? {
                                    "title": "Run command",
                                    "subtitle": commandText.length ? commandText : "(empty command)"
                                } : filteredEntries[index]
                                width: resultsColumn.width
                                implicitHeight: 48
                                radius: 6
                                color: listMouse.containsMouse ? (theme.programBg || "#16161e") : "transparent"
                                border.width: listMouse.containsMouse ? 1 : 0
                                border.color: theme.primary || "#7aa2f7"

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2

                                    Text {
                                        text: entry.title
                                        color: theme.fg || "#c0caf5"
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        text: commandMode ? "Press Enter to execute in shell" : entry.subtitle
                                        color: theme.primary || "#7aa2f7"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }

                                MouseArea {
                                    id: listMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (commandMode) {
                                            if (commandText.length > 0) {
                                                executeCommandRequested(commandText)
                                            }
                                        } else if (entry && entry.desktopId) {
                                            launchDesktopRequested(entry.desktopId)
                                        }
                                        closeRequested()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                color: theme.programBg || "#16161e"
                border.width: 2
                border.color: searchInput.focus ? theme.primary : "transparent"

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.margins: 12
                    focus: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: theme.fg
                    font.pixelSize: 16
                    selectByMouse: true

                    onActiveFocusChanged: {
                        if (!activeFocus && searchWindow.visible) {
                            closeOnBlurTimer.restart()
                        }
                    }

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Escape) {
                            searchWindow.closeRequested()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            searchWindow.submitPrimaryAction()
                            event.accepted = true
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search apps, files, or commands..."
                        color: theme.danger || "#f7768e"
                        visible: !searchInput.text && !searchInput.focus
                    }
                }
            }
        }
    }

    Timer {
        id: closeOnBlurTimer
        interval: 90
        repeat: false
        onTriggered: {
            if (searchWindow.visible && !searchInput.activeFocus) {
                searchWindow.closeRequested()
            }
        }
    }

    FolderListModel {
        id: systemDesktopModel
        folder: "file:///usr/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: searchWindow.rebuildAppEntries()
    }

    FolderListModel {
        id: systemProfileDesktopModel
        folder: "file:///run/current-system/sw/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: searchWindow.rebuildAppEntries()
    }

    FolderListModel {
        id: userProfileDesktopModel
        folder: "file:///etc/profiles/per-user/" + Quickshell.env("USER") + "/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: searchWindow.rebuildAppEntries()
    }

    FolderListModel {
        id: homeProfileDesktopModel
        folder: "file://" + Quickshell.env("HOME") + "/.nix-profile/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: searchWindow.rebuildAppEntries()
    }

    FolderListModel {
        id: userDesktopModel
        folder: "file://" + Quickshell.env("HOME") + "/.local/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        onCountChanged: searchWindow.rebuildAppEntries()
    }
}