import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import "../components"

ColumnLayout {
    id: view
    spacing: 10

    readonly property color accent: root.moduleColor("cpu", root.cpuUsage)
    readonly property color sysColor: "#e74c3c"
    readonly property color waitColor: "#f39c12"
    readonly property real idlePercent: Math.max(0, 100 - root.cpuUser - root.cpuSystem - root.cpuIowait)

    // 1. Hero Dashboard Card (Multi-segment Ring + Key-Value Specs)
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
                    maxValue: 100
                    segments: [
                        { value: root.cpuUser, color: view.accent },
                        { value: root.cpuSystem, color: view.sysColor },
                        { value: root.cpuIowait, color: view.waitColor }
                    ]
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    PlasmaComponents.Label {
                        text: Math.round(root.cpuUsage) + "%"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.features: ({ "tnum": 1 })
                        Layout.alignment: Qt.AlignHCenter
                    }
                    PlasmaComponents.Label {
                        text: "CPU"
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
                    label: root.tr("User", "用户态")
                    value: root.cpuUser.toFixed(1) + "%"
                }
                KeyValueRow {
                    showDot: true
                    dotColor: view.sysColor
                    label: root.tr("System", "内核态")
                    value: root.cpuSystem.toFixed(1) + "%"
                }
                KeyValueRow {
                    showDot: true
                    dotColor: view.waitColor
                    label: root.tr("IOWait", "IO 等待")
                    value: root.cpuIowait.toFixed(1) + "%"
                }
                KeyValueRow {
                    showDot: true
                    dotColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
                    label: root.tr("Idle", "空闲")
                    value: view.idlePercent.toFixed(1) + "%"
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
                text: root.tr("Usage History", "负载趋势")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                opacity: 0.8
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.Label {
                text: (root.cpuTempC > 0 ? root.formatTemp(root.cpuTempC) + "  ·  " : "")
                    + (root.cpuFreqMHz > 0 ? (root.cpuFreqMHz / 1000).toFixed(2) + " GHz  ·  " : "")
                    + root.tr("Load ", "负载 ") + (root.loadAverageText.split("  ")[0] || "--")
                font.pixelSize: 10
                font.features: ({ "tnum": 1 })
                opacity: 0.65
            }
        }

        SparklineCanvas {
            Layout.fillWidth: true
            height: 68
            values: root.cpuHistory
            lineColor: view.accent
            lineWidth: 2
            showGrid: true
            showBaseline: true
        }
    }

    // 3. Per-Core Matrix Card
    StatsCard {
        visible: Plasmoid.configuration.cpuShowCoreMatrix && root.cpuCoreUsages.length > 0

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: root.tr("Logical Cores", "逻辑核心")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                opacity: 0.8
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.Label {
                text: root.cpuCoreUsages.length + " " + root.tr("threads", "线程")
                font.pixelSize: 10
                opacity: 0.6
            }
        }

        BarChartCanvas {
            Layout.fillWidth: true
            height: 36
            values: root.cpuCoreUsages
            barColor: view.accent
            barGap: 2
        }
    }

    // 4. Linux System Info Card
    StatsCard {
        visible: Plasmoid.configuration.cpuShowSystemInfo

        PlasmaComponents.Label {
            text: root.cpuModelName ? root.cpuModelName : root.tr("System Info", "系统信息")
            font.pixelSize: 11
            font.weight: Font.DemiBold
            opacity: 0.85
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        KeyValueRow {
            label: root.tr("Load Avg (1/5/15m)", "平均负载 (1/5/15m)")
            value: root.loadAverageText
        }
        KeyValueRow {
            label: root.tr("CPU Governor", "调频策略")
            value: root.cpuGovernor
        }
        KeyValueRow {
            label: root.tr("Uptime", "运行时长")
            value: root.systemUptimeText
            showDivider: false
        }
    }

    // 5. Top Processes Card
    StatsCard {
        visible: root.topLimit > 0

        PlasmaComponents.Label {
            text: root.tr("Top Processes", "高占用进程")
            font.pixelSize: 11
            font.weight: Font.DemiBold
            opacity: 0.8
        }

        PlasmaComponents.Label {
            visible: root.topCpuProcesses.length === 0
            text: root.tr("Sampling processes...", "正在采集进程...")
            font.pixelSize: 11
            opacity: 0.55
        }

        Repeater {
            model: root.topCpuProcesses
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
                        width: parent.width * Math.max(0, Math.min(1, (Number(modelData.cpu) || 0) / 100))
                        height: parent.height
                        radius: 2.5
                        color: view.accent
                    }
                }

                PlasmaComponents.Label {
                    text: modelData.cpu + "%"
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
