import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    property var sortedApps: []

    function rebuildSortedApps() {
        root.sortedApps = AppSearch.list.slice().sort((a, b) => {
            const na = AppsConfig.resolveName(a.id, a.name).toLowerCase();
            const nb = AppsConfig.resolveName(b.id, b.name).toLowerCase();
            return na.localeCompare(nb);
        });
    }

    Timer {
        id: rebuildTimer
        interval: 1
        repeat: false
        onTriggered: root.rebuildSortedApps()
    }

    Connections {
        target: AppSearch
        function onListChanged() {
            rebuildTimer.restart();
        }
    }

    Connections {
        target: AppsConfig
        function onRenamedChanged() {
            rebuildTimer.restart();
        }
    }

    Component.onCompleted: rebuildTimer.start()

    ContentSection {
        icon: "tune"
        title: "Launcher"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledRadioButton {
                description: "Show all applications"
                checked: !AppsConfig.customMode
                onClicked: {
                    AppsConfig.customMode = false;
                    AppsConfig.saveToFile();
                }
            }

            StyledRadioButton {
                description: "Customize which applications appear"
                checked: AppsConfig.customMode
                onClicked: {
                    AppsConfig.customMode = true;
                    AppsConfig.saveToFile();
                }
            }

            StyledText {
                text: AppSearch.list.length + " applications"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.m3colors.m3onSurfaceVariant
                opacity: AppsConfig.customMode ? 1.0 : 0.5
            }

            ListView {
                id: appListView
                Layout.fillWidth: true
                Layout.preferredHeight: 400
                clip: true
                opacity: AppsConfig.customMode ? 1.0 : 0.5
                model: root.sortedApps
                reuseItems: true
                cacheBuffer: 800

                delegate: Rectangle {
                    id: appRow
                    required property var modelData
                    property var hiddenDeps: AppsConfig.hidden
                    property var renamedDeps: AppsConfig.renamed
                    property bool editing: false
                    property bool isHidden: AppsConfig.customMode && hiddenDeps.indexOf(appRow.modelData.id) !== -1
                    property bool isRenamed: renamedDeps[appRow.modelData.id] !== undefined && renamedDeps[appRow.modelData.id] !== ""
                    property string resolvedName: AppsConfig.resolveName(appRow.modelData.id, appRow.modelData.name)

                    width: appListView.width
                    height: 56
                    radius: Appearance.rounding.small
                    color: isHidden ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1
                    opacity: isHidden ? 0.55 : 1.0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        IconImage {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter
                            source: Quickshell.iconPath(appRow.modelData.icon, "image-missing")
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                visible: !appRow.editing

                                StyledText {
                                    Layout.fillWidth: true
                                    text: appRow.resolvedName
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: appRow.isRenamed
                                        ? Appearance.colors.colPrimary
                                        : (appRow.isHidden ? Appearance.m3colors.m3onSurfaceVariant : Appearance.colors.colOnLayer1)
                                    elide: Text.ElideRight
                                }

                                RippleButton {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    visible: appRow.isRenamed
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: "transparent"
                                    colBackgroundHover: Appearance.colors.colPrimaryContainer
                                    colRipple: Appearance.colors.colPrimaryContainerActive
                                    enabled: AppsConfig.customMode
                                    opacity: AppsConfig.customMode ? 1.0 : 0.3
                                    onClicked: AppsConfig.setRenamed(appRow.modelData.id, "")
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "undo"
                                        iconSize: 14
                                        color: Appearance.m3colors.m3onSurfaceVariant
                                    }
                                }

                                RippleButton {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: "transparent"
                                    colBackgroundHover: Appearance.colors.colPrimaryContainer
                                    colRipple: Appearance.colors.colPrimaryContainerActive
                                    enabled: AppsConfig.customMode
                                    opacity: AppsConfig.customMode ? 1.0 : 0.3
                                    onClicked: appRow.editing = true
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "edit"
                                        iconSize: 14
                                        color: Appearance.m3colors.m3onSurfaceVariant
                                    }
                                }
                            }

                            Loader {
                                Layout.fillWidth: true
                                active: appRow.editing
                                sourceComponent: RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    TextField {
                                        id: renameField
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        text: appRow.resolvedName
                                        placeholderText: appRow.modelData.name
                                        background: Rectangle {
                                            radius: Appearance.rounding.small
                                            color: Appearance.colors.colLayer2
                                            border.color: Appearance.colors.colPrimary
                                            border.width: renameField.activeFocus ? 2 : 1
                                        }
                                        color: Appearance.colors.colOnLayer1
                                        leftPadding: 6
                                        rightPadding: 6
                                        topPadding: 2
                                        bottomPadding: 2
                                        Keys.onReturnPressed: confirmRename()
                                        Keys.onEscapePressed: appRow.editing = false
                                        onActiveFocusChanged: {
                                            if (!activeFocus)
                                                appRow.editing = false;
                                        }
                                        Component.onCompleted: {
                                            forceActiveFocus();
                                            selectAll();
                                        }

                                        function confirmRename() {
                                            const trimmed = renameField.text.trim();
                                            AppsConfig.setRenamed(appRow.modelData.id, trimmed === appRow.modelData.name ? "" : trimmed);
                                            appRow.editing = false;
                                        }
                                    }

                                    RippleButton {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        buttonRadius: Appearance.rounding.full
                                        colBackground: "transparent"
                                        colBackgroundHover: Appearance.colors.colPrimaryContainer
                                        colRipple: Appearance.colors.colPrimaryContainerActive
                                        onClicked: renameField.confirmRename()
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "check"
                                            iconSize: 14
                                            color: Appearance.colors.colPrimary
                                        }
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: appRow.modelData.id
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: Appearance.m3colors.m3onSurfaceVariant
                                opacity: 0.6
                                elide: Text.ElideRight
                            }
                        }

                        StyledSwitch {
                            Layout.alignment: Qt.AlignVCenter
                            checked: !appRow.isHidden
                            enabled: AppsConfig.customMode
                            onToggled: AppsConfig.setHidden(appRow.modelData.id, !checked)
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Appearance.colors.colOutlineVariant
                        opacity: 0.35
                        visible: index < appListView.count - 1
                    }
                }

                footer: Item {
                    width: appListView.width
                    height: 4
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }
}


