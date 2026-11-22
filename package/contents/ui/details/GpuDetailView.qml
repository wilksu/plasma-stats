import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import "../components"

ColumnLayout {
    id: view
    spacing: 10

    readonly property color accent: root.moduleColor("gpu", root.gpuUsage)

    // 1. Hero Dashboard Card
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
                    value: root.gpuUsage
                    ringColor: view.accent
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    PlasmaComponents.Label {
                        text: Math.round(root.gpuUsage) + "%"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.features: ({ "tnum": 1 })
                        Layout.alignment: Qt.AlignHCenter
                    }
                    PlasmaComponents.Label {
                        text: "GPU"
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
                    label: root.tr("Device", "设备")
                    value: root.gpuName
                }
                KeyValueRow {
                    label: root.tr("Temperature", "温度")
                    value: root.formatTemp(root.gpuTempC)
                }
                KeyValueRow {
                    label: root.tr("Power", "功耗")
                    value: root.gpuPowerW > 0 ? root.gpuPowerW.toFixed(1) + " W" : "--"
                }
                KeyValueRow {
                    label: root.tr("Core Clock", "核心频率")
                    value: root.gpuFreqMHz > 0 ? Math.round(root.gpuFreqMHz) + " MHz" : "--"
                    showDivider: false
                }
            }
        }
    }

    // 2. Usage History Card
    StatsCard {
        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: root.tr("GPU Utilization", "显卡负载趋势")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                opacity: 0.8
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.Label {
                visible: root.discoveredGpus.length > 0
                text: root.resolvedGpuId.toUpperCase()
                font.pixelSize: 10
                opacity: 0.6
            }
        }

        SparklineCanvas {
            Layout.fillWidth: true
            height: 76
            values: root.gpuHistory
            lineColor: view.accent
            lineWidth: 2
            showGrid: true
            showBaseline: true
        }
    }

    // 3. VRAM Card
    StatsCard {
        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: root.tr("Video Memory (VRAM)", "显存占用 (VRAM)")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                opacity: 0.8
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.Label {
                text: root.gpuTotalVramBytes > 0
                    ? root.formatBytes(root.gpuUsedVramBytes) + " / " + root.formatBytes(root.gpuTotalVramBytes) + " (" + Math.round(root.gpuVramPercent) + "%)"
                    : "--"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.features: ({ "tnum": 1 })
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.gpuVramPercent / 100))
                height: parent.height
                radius: 4
                color: view.accent
            }
        }

        PlasmaComponents.Label {
            visible: root.discoveredGpus.length > 1
            text: root.tr("Detected GPUs: " + root.discoveredGpus.join(", "), "已检测到显卡: " + root.discoveredGpus.join(", "))
            font.pixelSize: 10
            opacity: 0.6
        }
    }
}
