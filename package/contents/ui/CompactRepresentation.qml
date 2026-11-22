import QtQuick
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import "components"

Item {
    id: compactRoot

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int spacing: {
        var d = Plasmoid.configuration.panelDensity || "normal"
        if (d === "compact") return 4
        if (d === "relaxed") return 12
        return 8
    }
    readonly property var tabularFeatures: Plasmoid.configuration.useMonospaceNumbers ? ({ "tnum": 1 }) : ({})

    Layout.minimumWidth: isVertical ? -1 : mainLayout.implicitWidth + Kirigami.Units.smallSpacing * 2
    Layout.preferredWidth: isVertical ? -1 : mainLayout.implicitWidth + Kirigami.Units.smallSpacing * 2
    Layout.minimumHeight: isVertical ? mainLayout.implicitHeight + Kirigami.Units.smallSpacing * 2 : -1
    Layout.preferredHeight: isVertical ? mainLayout.implicitHeight + Kirigami.Units.smallSpacing * 2 : -1

    GridLayout {
        id: mainLayout
        anchors.centerIn: parent
        flow: compactRoot.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columnSpacing: compactRoot.spacing
        rowSpacing: compactRoot.spacing

        Repeater {
            model: root.orderedModules

            delegate: Loader {
                required property string modelData
                visible: root.isModuleEnabled(modelData)
                active: visible
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                sourceComponent: {
                    if (modelData === "cpu") return cpuModuleComp
                    if (modelData === "gpu") return gpuModuleComp
                    if (modelData === "ram") return ramModuleComp
                    if (modelData === "network") return netModuleComp
                    return null
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Shared Module Wrapper (hover + click to open tab)
    // -------------------------------------------------------------------------
    component ModuleTile: Rectangle {
        id: tile
        property string moduleId: ""
        default property alias content: innerRow.data

        implicitWidth: innerRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        implicitHeight: Math.max(24, innerRow.implicitHeight + 4)
        radius: Kirigami.Units.smallSpacing
        color: mouseArea.containsMouse
            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
            : (root.expanded && root.activeTab === moduleId
                ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12)
                : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            id: innerRow
            anchors.centerIn: parent
            spacing: 4
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openModule(tile.moduleId)
        }
    }

    // -------------------------------------------------------------------------
    // CPU Module
    // -------------------------------------------------------------------------
    Component {
        id: cpuModuleComp
        ModuleTile {
            moduleId: "cpu"
            readonly property string style: Plasmoid.configuration.cpuPanelStyle
            readonly property color accent: root.moduleColor("cpu", root.cpuUsage)

            ColumnLayout {
                spacing: 0
                visible: Plasmoid.configuration.showModuleLabels
                PlasmaComponents.Label {
                    text: "CPU"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    opacity: 0.72
                    Layout.alignment: Qt.AlignHCenter
                }
                PlasmaComponents.Label {
                    text: Math.round(root.cpuUsage) + "%"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.features: compactRoot.tabularFeatures
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            BarChartCanvas {
                visible: style === "barchart"
                implicitWidth: Plasmoid.configuration.cpuMultiCore ? Math.max(18, Math.min(44, Math.max(4, root.cpuCoreUsages.length) * 2.5)) : 10
                implicitHeight: 20
                values: (Plasmoid.configuration.cpuMultiCore && root.cpuCoreUsages.length > 0) ? root.cpuCoreUsages : [root.cpuUsage]
                barColor: accent
            }

            SparklineCanvas {
                visible: style === "linechart"
                implicitWidth: 34
                implicitHeight: 20
                values: root.cpuHistory
                lineColor: accent
            }

            ColumnLayout {
                visible: style === "label" || Plasmoid.configuration.cpuShowTemperature || Plasmoid.configuration.cpuShowFrequency
                spacing: 0
                PlasmaComponents.Label {
                    visible: style === "label" && !Plasmoid.configuration.showModuleLabels
                    text: Math.round(root.cpuUsage) + "%"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.features: compactRoot.tabularFeatures
                }
                PlasmaComponents.Label {
                    visible: Plasmoid.configuration.cpuShowTemperature && root.cpuTempC > 0
                    text: root.formatTemp(root.cpuTempC)
                    font.pixelSize: 9
                    opacity: 0.85
                    font.features: compactRoot.tabularFeatures
                }
                PlasmaComponents.Label {
                    visible: Plasmoid.configuration.cpuShowFrequency && root.cpuFreqMHz > 0
                    text: (root.cpuFreqMHz / 1000).toFixed(1) + "G"
                    font.pixelSize: 9
                    opacity: 0.75
                    font.features: compactRoot.tabularFeatures
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // GPU Module
    // -------------------------------------------------------------------------
    Component {
        id: gpuModuleComp
        ModuleTile {
            moduleId: "gpu"
            readonly property string style: Plasmoid.configuration.gpuPanelStyle
            readonly property color accent: root.moduleColor("gpu", root.gpuUsage)

            ColumnLayout {
                spacing: 0
                visible: Plasmoid.configuration.showModuleLabels
                PlasmaComponents.Label {
                    text: "GPU"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    opacity: 0.72
                    Layout.alignment: Qt.AlignHCenter
                }
                PlasmaComponents.Label {
                    text: Math.round(root.gpuUsage) + "%"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.features: compactRoot.tabularFeatures
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            SparklineCanvas {
                visible: style === "linechart"
                implicitWidth: 32
                implicitHeight: 20
                values: root.gpuHistory
                lineColor: accent
            }

            BarChartCanvas {
                visible: style === "barchart"
                implicitWidth: Plasmoid.configuration.gpuShowVram ? 14 : 9
                implicitHeight: 20
                values: Plasmoid.configuration.gpuShowVram && root.gpuTotalVramBytes > 0
                    ? [root.gpuUsage, root.gpuVramPercent]
                    : [root.gpuUsage]
                barColor: accent
            }

            ColumnLayout {
                visible: style === "label" || Plasmoid.configuration.gpuShowTemperature || Plasmoid.configuration.gpuShowVram
                spacing: 0
                PlasmaComponents.Label {
                    visible: style === "label" && !Plasmoid.configuration.showModuleLabels
                    text: Math.round(root.gpuUsage) + "%"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.features: compactRoot.tabularFeatures
                }
                PlasmaComponents.Label {
                    visible: Plasmoid.configuration.gpuShowTemperature && root.gpuTempC > 0
                    text: root.formatTemp(root.gpuTempC)
                    font.pixelSize: 9
                    opacity: 0.85
                    font.features: compactRoot.tabularFeatures
                }
                PlasmaComponents.Label {
                    visible: Plasmoid.configuration.gpuShowVram && root.gpuTotalVramBytes > 0
                    text: root.formatBytes(root.gpuUsedVramBytes, 1)
                    font.pixelSize: 9
                    opacity: 0.75
                    font.features: compactRoot.tabularFeatures
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // RAM Module
    // -------------------------------------------------------------------------
    Component {
        id: ramModuleComp
        ModuleTile {
            moduleId: "ram"
            readonly property string style: Plasmoid.configuration.ramPanelStyle
            readonly property color accent: root.moduleColor("ram", root.ramPercent)
            readonly property string ramText: Plasmoid.configuration.ramDisplayFormat === "gb"
                ? (root.ramUsedBytes / (1024 * 1024 * 1024)).toFixed(1) + "G"
                : Math.round(root.ramPercent) + "%"

            ColumnLayout {
                spacing: 0
                visible: Plasmoid.configuration.showModuleLabels
                PlasmaComponents.Label {
                    text: "RAM"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    opacity: 0.72
                    Layout.alignment: Qt.AlignHCenter
                }
                PlasmaComponents.Label {
                    text: ramText
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.features: compactRoot.tabularFeatures
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            RingChartCanvas {
                visible: style === "pie"
                implicitWidth: 20
                implicitHeight: 20
                value: root.ramPercent
                ringColor: accent
                filledPie: false
            }

            BarChartCanvas {
                visible: style === "barchart"
                implicitWidth: (Plasmoid.configuration.ramShowSwap && root.swapTotalBytes > 0) ? 14 : 9
                implicitHeight: 20
                values: (Plasmoid.configuration.ramShowSwap && root.swapTotalBytes > 0)
                    ? [root.ramPercent, root.swapPercent]
                    : [root.ramPercent]
                barColor: accent
            }

            PlasmaComponents.Label {
                visible: style === "label" && !Plasmoid.configuration.showModuleLabels
                text: ramText
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.features: compactRoot.tabularFeatures
            }
        }
    }

    // -------------------------------------------------------------------------
    // Network Module
    // -------------------------------------------------------------------------
    Component {
        id: netModuleComp
        ModuleTile {
            moduleId: "network"
            readonly property string style: Plasmoid.configuration.networkPanelStyle
            readonly property color downColor: Plasmoid.configuration.networkDownloadColor
            readonly property color upColor: Plasmoid.configuration.networkUploadColor

            DualSparklineCanvas {
                visible: style === "linechart"
                implicitWidth: 32
                implicitHeight: 20
                primaryValues: root.netDownloadHistory
                secondaryValues: root.netUploadHistory
                primaryColor: downColor
                secondaryColor: upColor
            }

            TextMetrics {
                id: compactSpeedMetrics
                font.pixelSize: 10
                font.weight: Font.Medium
                font.features: compactRoot.tabularFeatures
                text: "999K"
            }

            TextMetrics {
                id: fullSpeedMetrics
                font.pixelSize: 10
                font.weight: Font.Medium
                font.features: compactRoot.tabularFeatures
                text: "999.9 MB/s"
            }

            component NetArrow: Canvas {
                property bool up: true
                property color arrowColor: "#3498db"
                implicitWidth: 9
                implicitHeight: 11
                onArrowColorChanged: requestPaint()
                onUpChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = arrowColor
                    ctx.lineWidth = 1.6
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    var cx = width / 2
                    ctx.beginPath()
                    if (up) {
                        ctx.moveTo(cx, height - 1.5)
                        ctx.lineTo(cx, 2.0)
                        ctx.moveTo(cx - 2.8, 4.8)
                        ctx.lineTo(cx, 1.8)
                        ctx.lineTo(cx + 2.8, 4.8)
                    } else {
                        ctx.moveTo(cx, 1.5)
                        ctx.lineTo(cx, height - 2.0)
                        ctx.moveTo(cx - 2.8, height - 4.8)
                        ctx.lineTo(cx, height - 1.8)
                        ctx.lineTo(cx + 2.8, height - 4.8)
                    }
                    ctx.stroke()
                }
            }

            ColumnLayout {
                spacing: 0

                RowLayout {
                    spacing: 2
                    NetArrow {
                        up: true
                        arrowColor: upColor
                    }
                    PlasmaComponents.Label {
                        text: root.formatSpeed(root.netUploadBps, style !== "arrows")
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        font.features: compactRoot.tabularFeatures
                        Layout.preferredWidth: style === "arrows" ? Math.ceil(fullSpeedMetrics.width) : Math.ceil(compactSpeedMetrics.width)
                        horizontalAlignment: Text.AlignRight
                    }
                }

                RowLayout {
                    spacing: 2
                    NetArrow {
                        up: false
                        arrowColor: downColor
                    }
                    PlasmaComponents.Label {
                        text: root.formatSpeed(root.netDownloadBps, style !== "arrows")
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        font.features: compactRoot.tabularFeatures
                        Layout.preferredWidth: style === "arrows" ? Math.ceil(fullSpeedMetrics.width) : Math.ceil(compactSpeedMetrics.width)
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
