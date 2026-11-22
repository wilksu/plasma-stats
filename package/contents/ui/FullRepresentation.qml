import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import "details"

Item {
    id: fullRoot

    readonly property int maxPopupHeight: (Screen.desktopAvailableHeight > 0 ? Screen.desktopAvailableHeight - 80 : 820)
    readonly property Item currentDetailItem: {
        if (root.activeTab === "gpu") return gpuDetailView
        if (root.activeTab === "ram") return ramDetailView
        if (root.activeTab === "network") return netDetailView
        return cpuDetailView
    }
    readonly property int currentDetailHeight: currentDetailItem ? currentDetailItem.implicitHeight : 320
    readonly property int desiredHeight: headerRow.implicitHeight + currentDetailHeight + Kirigami.Units.mediumSpacing * 3 + 8

    Layout.minimumWidth: 340
    Layout.minimumHeight: 260
    Layout.preferredWidth: 390
    Layout.preferredHeight: Math.min(maxPopupHeight, Math.max(260, desiredHeight))

    function tabLabel(mod) {
        if (mod === "cpu") return "CPU"
        if (mod === "gpu") return "GPU"
        if (mod === "ram") return root.tr("RAM", "内存")
        if (mod === "network") return root.tr("Network", "网络")
        return mod
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: Kirigami.Units.mediumSpacing
        spacing: Kirigami.Units.mediumSpacing

        // Top Segmented Tab Bar + Settings Button
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: root.orderedModules
                        delegate: Rectangle {
                            required property string modelData
                            visible: root.isModuleEnabled(modelData)
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Kirigami.Units.smallSpacing - 2
                            color: root.activeTab === modelData
                                ? Kirigami.Theme.highlightColor
                                : (tabMouse.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            PlasmaComponents.Label {
                                anchors.centerIn: parent
                                text: fullRoot.tabLabel(modelData)
                                font.pixelSize: 12
                                font.weight: root.activeTab === modelData ? Font.Bold : Font.Medium
                                color: root.activeTab === modelData ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = modelData
                            }
                        }
                    }
                }
            }

            PlasmaComponents.ToolButton {
                icon.name: "configure"
                PlasmaComponents.ToolTip.text: root.tr("Configure Plasma Stats...", "配置 Plasma Stats...")
                PlasmaComponents.ToolTip.visible: hovered
                onClicked: {
                    var act = Plasmoid.internalAction("configure")
                    if (act) act.trigger()
                }
            }
        }

        // Scrollable StackLayout (keeps views alive for instant, stutter-free tab switching)
        PlasmaComponents.ScrollView {
            id: detailScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            contentHeight: fullRoot.currentDetailHeight

            StackLayout {
                width: detailScroll.availableWidth
                currentIndex: {
                    if (root.activeTab === "gpu") return 1
                    if (root.activeTab === "ram") return 2
                    if (root.activeTab === "network") return 3
                    return 0
                }

                CpuDetailView { id: cpuDetailView; Layout.fillWidth: true }
                GpuDetailView { id: gpuDetailView; Layout.fillWidth: true }
                RamDetailView { id: ramDetailView; Layout.fillWidth: true }
                NetworkDetailView { id: netDetailView; Layout.fillWidth: true }
            }
        }
    }
}
