// Searchbar.qml
import Quickshell
import Quickshell.Wayland
import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Layouts

Item {
    id: searchController

    // ==========================================
    // 1. STATE & LOGIC
    // ==========================================
    property var theme
    property bool searchOpen
    property int overlayPadding: 10
    property int frameRadius: 14
    
    // NEW: Track which item is currently highlighted!
    property int selectedIndex: 0 
    
    property var appEntries: []
    property var filteredEntries: []
    property bool commandMode: searchInput.text.length > 0 && searchInput.text.charAt(0) === ">"
    property string commandText: commandMode ? searchInput.text.slice(1).trim() : ""
    property string queryText: commandMode ? "" : searchInput.text.trim().toLowerCase()
    
    property real maxOverlayHeight: (inputWindow.screen && inputWindow.screen.height > 0) ? inputWindow.screen.height * 0.4 : 432

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
            if (!fileName || !fileName.endsWith(".desktop") || seen[fileName]) { continue; }
            seen[fileName] = true;
            into.push({ "desktopId": fileName, "title": prettyNameFromDesktopId(fileName), "subtitle": fileName });
        }
    }

    function rebuildAppEntries() {
        var entries = []; var seen = {};
        collectDesktopEntries(systemDesktopModel, entries, seen);
        collectDesktopEntries(systemProfileDesktopModel, entries, seen);
        collectDesktopEntries(userProfileDesktopModel, entries, seen);
        collectDesktopEntries(homeProfileDesktopModel, entries, seen);
        collectDesktopEntries(userDesktopModel, entries, seen);
        entries.sort(function (a, b) { return a.title.localeCompare(b.title); });
        appEntries = entries;
        applyFilter();
    }

    function applyFilter() {
        if (!queryText.length) { filteredEntries = []; return; }
        var query = queryText.toLowerCase(); var matches = [];
        for (var i = 0; i < appEntries.length; i++) {
            var item = appEntries[i];
            if (item.title.toLowerCase().indexOf(query) !== -1 || item.subtitle.toLowerCase().indexOf(query) !== -1) { matches.push(item); }
            if (matches.length >= 30) { break; }
        }
        filteredEntries = matches;
        
        // NEW: Reset selection to the top item whenever you type a new letter
        selectedIndex = 0; 
    }

    function submitPrimaryAction() {
        if (commandMode) {
            if (commandText.length) { executeCommandRequested(commandText); }
            closeRequested(); return;
        }
        
        // NEW: Launch the item you highlighted, rather than just the first item!
        if (filteredEntries.length > 0 && selectedIndex >= 0 && selectedIndex < filteredEntries.length) {
            launchDesktopRequested(filteredEntries[selectedIndex].desktopId);
        } else if (searchInput.text.trim().length > 0) {
            openLauncherRequested(searchInput.text.trim());
        }
        closeRequested();
    }

    onQueryTextChanged: applyFilter()
    Component.onCompleted: rebuildAppEntries()

    // ==========================================
    // 2. WINDOW 1: THE STATIC SEARCH BOX
    // ==========================================
    PanelWindow {
        id: inputWindow
        
        anchors { bottom: true }
        margins { bottom: 20 }
        
        visible: searchController.searchOpen
        implicitHeight: 50
        implicitWidth: 600
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        onVisibleChanged: {
            if (visible) {
                searchInput.forceActiveFocus()
                searchInput.cursorPosition = searchInput.text.length
            } else {
                searchInput.text = ""
            }
        }

        Shortcut { sequence: "Escape"; onActivated: searchController.closeRequested() }

        MouseArea {
        id: globalMouseTracker
        anchors.fill: parent // This covers both windows
        hoverEnabled: true
        acceptedButtons: Qt.NoButton // Let clicks pass through
        
        onEntered: {
            // Mouse is over the UI, keep it open!
            searchController.searchOpen = true 
        }
    }

        Rectangle {
            anchors.fill: parent
            color: theme.programBg || "#16161e"
            radius: frameRadius
            border.width: 2
            border.color: searchInput.focus ? (theme.primary || "#7aa2f7") : "transparent"

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.margins: 15
                focus: true
                verticalAlignment: TextInput.AlignVCenter
                color: theme.fg || "#c0caf5"
                font.pixelSize: 16
                selectByMouse: true

                onActiveFocusChanged: {
                    if (!activeFocus && inputWindow.visible) { closeOnBlurTimer.restart() }
                }

                // NEW: Intercepting Up and Down arrows while keeping focus on the text box!
                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape) {
                        searchController.closeRequested(); event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        searchController.submitPrimaryAction(); event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        searchController.selectedIndex = Math.max(0, searchController.selectedIndex - 1);
                        resultsList.positionViewAtIndex(searchController.selectedIndex, ListView.Contain);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        var maxIdx = commandMode ? 0 : Math.max(0, filteredEntries.length - 1);
                        searchController.selectedIndex = Math.min(maxIdx, searchController.selectedIndex + 1);
                        resultsList.positionViewAtIndex(searchController.selectedIndex, ListView.Contain);
                        event.accepted = true;
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
    }

    // ==========================================
    // 3. WINDOW 2: THE ADAPTIVE RESULTS CARD
    // ==========================================
    PanelWindow {
        id: resultsWindow
        
        anchors { bottom: true }
        margins { bottom: 80 } 
        
        visible: searchController.searchOpen && searchInput.text.trim().length > 0
        implicitHeight: maxOverlayHeight
        implicitWidth: 600
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            id: resultsBg
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right;
            height: Math.min(resultsList.contentHeight + 20, maxOverlayHeight)
            color: theme.bg || "#1a1b26"
            radius: frameRadius
            border.width: 1
            border.color: theme.primary || "#7aa2f7"
            clip: true

            ListView {
                id: resultsList
                anchors.fill: parent
                anchors.margins: 10
                
                model: commandMode ? 1 : filteredEntries.length
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                delegate: Rectangle {
                    required property int index
                    readonly property var entry: commandMode ? {
                        "title": "Run command",
                        "subtitle": commandText.length ? commandText : "(empty command)"
                    } : filteredEntries[index]
                    
                    // NEW: Is this the currently selected item?
                    readonly property bool isActive: searchController.selectedIndex === index
                    
                    width: resultsList.width
                    implicitHeight: 48
                    radius: 6
                    
                    // NEW: Highlight reacts to the isActive boolean
                    color: isActive ? (theme.programBg || "#16161e") : "transparent"
                    border.width: isActive ? 1 : 0
                    border.color: theme.primary || "#7aa2f7"

                    Column {
                        anchors.fill: parent; anchors.margins: 8; spacing: 2
                        Text { text: entry.title; color: theme.fg || "#c0caf5"; font.pixelSize: 14; elide: Text.ElideRight; width: parent.width }
                        Text { text: commandMode ? "Press Enter to execute in shell" : entry.subtitle; color: theme.primary || "#7aa2f7"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                    }

                    MouseArea {
                        id: listMouse
                        anchors.fill: parent; hoverEnabled: true
                        
                        // NEW: When the mouse enters this item, tell the system it's the active one!
                        onEntered: searchController.selectedIndex = index
                        
                        onClicked: {
                            if (commandMode) {
                                if (commandText.length > 0) { searchController.executeCommandRequested(commandText) }
                            } else if (entry && entry.desktopId) {
                                searchController.launchDesktopRequested(entry.desktopId)
                            }
                            searchController.closeRequested()
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 4. TIMERS & DATA MODELS
    // ==========================================
    Timer {
        id: closeOnBlurTimer
        interval: 90; repeat: false
        onTriggered: {
            if (inputWindow.visible && !searchInput.activeFocus) { searchController.closeRequested() }
        }
    }

    FolderListModel { id: systemDesktopModel; folder: "file:///usr/share/applications"; nameFilters: ["*.desktop"]; showDirs: false; onCountChanged: searchController.rebuildAppEntries() }
    FolderListModel { id: systemProfileDesktopModel; folder: "file:///run/current-system/sw/share/applications"; nameFilters: ["*.desktop"]; showDirs: false; onCountChanged: searchController.rebuildAppEntries() }
    FolderListModel { id: userProfileDesktopModel; folder: "file:///etc/profiles/per-user/" + Quickshell.env("USER") + "/share/applications"; nameFilters: ["*.desktop"]; showDirs: false; onCountChanged: searchController.rebuildAppEntries() }
    FolderListModel { id: homeProfileDesktopModel; folder: "file://" + Quickshell.env("HOME") + "/.nix-profile/share/applications"; nameFilters: ["*.desktop"]; showDirs: false; onCountChanged: searchController.rebuildAppEntries() }
    FolderListModel { id: userDesktopModel; folder: "file://" + Quickshell.env("HOME") + "/.local/share/applications"; nameFilters: ["*.desktop"]; showDirs: false; onCountChanged: searchController.rebuildAppEntries() }
}