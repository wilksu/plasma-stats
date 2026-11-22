import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import "../components"

ColumnLayout {
    id: view
    spacing: 10

    readonly property color downColor: Plasmoid.configuration.networkDownloadColor
    readonly property color upColor: Plasmoid.configuration.networkUploadColor

    // 1. Speed Summary Card
    StatsCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                RowLayout {
                    spacing: 5
                    Rectangle { width: 8; height: 8; radius: 4; color: view.downColor }
                    PlasmaComponents.Label { text: root.tr("Download", "下载速率"); font.pixelSize: 11; opacity: 0.7 }
                }
                PlasmaComponents.Label {
                    text: root.formatSpeed(root.netDownloadBps, false)
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    font.features: ({ "tnum": 1 })
                    color: view.downColor
                }
            }

            Rectangle {
                width: 1
                Layout.fillHeight: true
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                RowLayout {
                    spacing: 5
                    Rectangle { width: 8; height: 8; radius: 4; color: view.upColor }
                    PlasmaComponents.Label { text: root.tr("Upload", "上传速率"); font.pixelSize: 11; opacity: 0.7 }
                }
                PlasmaComponents.Label {
                    text: root.formatSpeed(root.netUploadBps, false)
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    font.features: ({ "tnum": 1 })
                    color: view.upColor
                }
            }
        }
    }

    // 2. Dual Sparkline Card
    StatsCard {
        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: root.tr("Throughput History", "实时吞吐曲线")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                opacity: 0.8
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.Label {
                text: root.tr("Peak ", "峰值 ") + root.formatSpeed(Math.max(root.netPeakDownloadBps, root.netPeakUploadBps), false)
                font.pixelSize: 10
                font.features: ({ "tnum": 1 })
                opacity: 0.65
            }
        }

        DualSparklineCanvas {
            Layout.fillWidth: true
            height: 76
            primaryValues: root.netDownloadHistory
            secondaryValues: root.netUploadHistory
            primaryColor: view.downColor
            secondaryColor: view.upColor
            lineWidth: 2
        }
    }

    // 3. Connection & Interface Card
    StatsCard {
        visible: Plasmoid.configuration.networkShowConnectionInfo

        KeyValueRow {
            showDot: true
            dotColor: view.downColor
            label: root.tr("Peak Download / Upload", "峰值下载 / 上传")
            value: root.formatSpeed(root.netPeakDownloadBps, false) + "  /  " + root.formatSpeed(root.netPeakUploadBps, false)
        }
        KeyValueRow {
            label: root.tr("Total Received / Sent", "累计接收 / 发送")
            value: root.formatBytes(root.netTotalDownloadBytes) + "  /  " + root.formatBytes(root.netTotalUploadBytes)
        }
        KeyValueRow {
            label: root.tr("Active Interface", "当前网卡")
            value: root.resolvedNetIface === "all" && root.netActiveIface !== "--"
                ? root.netActiveIface + " (all)"
                : root.resolvedNetIface
        }
        KeyValueRow {
            label: "IPv4"
            value: root.netIpv4
        }
        KeyValueRow {
            label: root.tr("Default Gateway", "默认网关")
            value: root.netGateway
            showDivider: false
        }
    }

    // 4. Active Network Processes Card (via KDE ProcessDataModel netInbound/netOutbound)
    StatsCard {
        visible: Plasmoid.configuration.networkShowTopProcesses

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: root.tr("Active Network Processes", "活跃网络进程")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                opacity: 0.8
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.Label {
                text: "↓ / ↑"
                font.pixelSize: 10
                opacity: 0.6
            }
        }

        PlasmaComponents.Label {
            visible: root.topNetProcesses.length === 0
            text: root.tr("No active network traffic per process", "当前暂无进程产生明显网络流量")
            font.pixelSize: 11
            opacity: 0.55
        }

        Repeater {
            model: root.topNetProcesses
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

                PlasmaComponents.Label {
                    text: "↓ " + root.formatSpeed(modelData.netDown, false)
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })
                    color: view.downColor
                }

                PlasmaComponents.Label {
                    text: "↑ " + root.formatSpeed(modelData.netUp, false)
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })
                    color: view.upColor
                }
            }
        }
    }
}
