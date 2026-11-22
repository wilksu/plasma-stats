import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import "../components"

ColumnLayout {
    id: view
    spacing: 10

    readonly property color accent: root.moduleColor("ram", root.ramPercent)
    readonly property color cacheColor: "#3498db"
    readonly property color freeColor: "#2ecc71"
    readonly property real cachedTotalBytes: root.ramCacheBytes + root.ramBufferBytes

    // 1. Hero Dashboard Card (Multi-segment Ring + Breakdown)
    StatsCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Item {
                implicitWidth: 78
                implicitHeight: 78

                RingChartCanvas {
                    anchors.fill: parent
                    lineWidth: 8
                    maxValue: Math.max(1, root.ramTotalBytes)
                    value: root.ramUsedBytes
                    ringColor: view.accent
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    PlasmaComponents.Label {
                        text: Math.round(root.ramPercent) + "%"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.features: ({ "tnum": 1 })
                        Layout.alignment: Qt.AlignHCenter
                    }
                    PlasmaComponents.Label {
                        text: "RAM"
                        font.pixelSize: 9
                        opacity: 0.6
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                KeyValueRow {
                    showDot: true
                    dotColor: view.accent
                    label: root.tr("Used", "已用")
                    value: root.formatBytes(root.ramUsedBytes)
                }
                KeyValueRow {
                    showDot: true
                    dotColor: view.freeColor
                    label: root.tr("Available", "可用")
                    value: root.formatBytes(root.ramAvailableBytes)
                }
                KeyValueRow {
                    showDot: true
                    dotColor: view.cacheColor
                    label: root.tr("Cache / Buffer", "缓存 / 缓冲")
                    value: root.formatBytes(view.cachedTotalBytes)
                }
                KeyValueRow {
                    label: root.tr("Total", "总容量")
                    value: root.formatBytes(root.ramTotalBytes)
                    showDivider: false
                }
            }
        }
    }

    // 2. History Card
    StatsCard {
        PlasmaComponents.Label {
            text: root.tr("Memory Pressure", "内存占用趋势")
            font.pixelSize: 11
            font.weight: Font.DemiBold
            opacity: 0.8
        }

        SparklineCanvas {
            Layout.fillWidth: true
            height: 64
            values: root.ramHistory
            lineColor: view.accent
            lineWidth: 2
            showGrid: true
            showBaseline: true
        }
    }

    // 3. Swap Card
    StatsCard {
        visible: Plasmoid.configuration.ramShowSwap || root.swapTotalBytes > 0

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: root.tr("Swap", "交换分区 (Swap)")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                opacity: 0.8
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.Label {
                text: root.swapTotalBytes > 0
                    ? root.formatBytes(root.swapUsedBytes) + " / " + root.formatBytes(root.swapTotalBytes) + " (" + Math.round(root.swapPercent) + "%)"
                    : root.tr("Not configured", "未启用")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.features: ({ "tnum": 1 })
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 7
            radius: 3.5
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.swapPercent / 100))
                height: parent.height
                radius: 3.5
                color: "#f39c12"
            }
        }
    }

    // 4. Top RAM Processes Card
    StatsCard {
        visible: Plasmoid.configuration.ramShowTopProcesses

        PlasmaComponents.Label {
            text: root.tr("Top Memory Processes", "高内存占用进程")
            font.pixelSize: 11
            font.weight: Font.DemiBold
            opacity: 0.8
        }

        PlasmaComponents.Label {
            visible: root.topRamProcesses.length === 0
            text: root.tr("Sampling processes...", "正在采集进程...")
            font.pixelSize: 11
            opacity: 0.55
        }

        Repeater {
            model: root.topRamProcesses
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 8

                PlasmaComponents.Label {
                    text: modelData.name
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 56
                    height: 5
                    radius: 2.5
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, (Number(modelData.mem) || 0) / 100))
                        height: parent.height
                        radius: 2.5
                        color: view.accent
                    }
                }

                PlasmaComponents.Label {
                    text: modelData.mem + "%"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })
                    Layout.minimumWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
