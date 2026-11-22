import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

import "../I18n.js" as I18n
import "../components"

KCM.SimpleKCM {
    id: page

    property alias cfg_networkEnabled: enabledCheck.checked
    property string cfg_networkInterface: "all"
    property alias cfg_networkPanelStyle: styleCombo.currentValue
    property alias cfg_networkUnit: unitCombo.currentValue
    property alias cfg_networkHideNoise: noiseCheck.checked
    property alias cfg_networkShowTopProcesses: topProcCheck.checked
    property alias cfg_networkShowConnectionInfo: connInfoCheck.checked
    property alias cfg_networkDownloadColor: downColorPicker.selectedColor
    property alias cfg_networkUploadColor: upColorPicker.selectedColor

    readonly property string lang: Plasmoid.configuration.language || "auto"
    function tr(en, zh) { return I18n.tr(en, zh, lang) }

    property var discoveredIfaces: []

    Plasma5Support.DataSource {
        id: netIfacesSource
        engine: "executable"
        connectedSources: ["ls -1 /sys/class/net"]
        interval: 0
        onNewData: function(sourceName, data) {
            if (!data || !data.stdout) return
            var lines = String(data.stdout).split("\n")
            var list = []
            for (var i = 0; i < lines.length; i++) {
                var iface = lines[i].trim()
                if (iface && iface !== "lo" && list.indexOf(iface) === -1) {
                    list.push(iface)
                }
            }
            page.discoveredIfaces = list
            var idx = ifaceCombo.indexOfValue(page.cfg_networkInterface)
            if (idx >= 0) ifaceCombo.currentIndex = idx
        }
    }

    readonly property var ifaceChoices: {
        var list = [{ text: page.tr("All Active Interfaces", "全部活跃网卡"), value: "all" }]
        var seen = { "all": true, "lo": true }
        for (var i = 0; i < page.discoveredIfaces.length; i++) {
            var name = page.discoveredIfaces[i]
            if (!seen[name]) {
                seen[name] = true
                list.push({ text: name, value: name })
            }
        }
        if (page.cfg_networkInterface && !seen[page.cfg_networkInterface]) {
            list.push({ text: page.cfg_networkInterface, value: page.cfg_networkInterface })
        }
        return list
    }

    Kirigami.FormLayout {
        QQC2.Switch {
            id: enabledCheck
            Kirigami.FormData.label: page.tr("Enable Network:", "启用网络：")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("Panel Widget", "顶栏小部件")
        }

        QQC2.ComboBox {
            id: ifaceCombo
            Kirigami.FormData.label: page.tr("Interface:", "网卡接口：")
            enabled: enabledCheck.checked
            textRole: "text"
            valueRole: "value"
            model: page.ifaceChoices
            onActivated: page.cfg_networkInterface = currentValue
            Component.onCompleted: {
                var idx = indexOfValue(page.cfg_networkInterface)
                if (idx >= 0) currentIndex = idx
            }
        }

        QQC2.ComboBox {
            id: styleCombo
            Kirigami.FormData.label: page.tr("Widget style:", "显示样式：")
            enabled: enabledCheck.checked
            textRole: "text"
            valueRole: "value"
            model: [
                { text: page.tr("Compact Speed (Two-line)", "紧凑双行速率"), value: "speed" },
                { text: page.tr("Line Chart + Speed", "双折线图 + 速率"), value: "linechart" },
                { text: page.tr("Arrows + Full Unit", "箭头 + 完整单位"), value: "arrows" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_networkPanelStyle)
        }

        QQC2.ComboBox {
            id: unitCombo
            Kirigami.FormData.label: page.tr("Speed unit:", "速率单位：")
            enabled: enabledCheck.checked
            textRole: "text"
            valueRole: "value"
            model: [
                { text: page.tr("Bytes (KB/s, MB/s)", "字节 (KB/s, MB/s)"), value: "bytes" },
                { text: page.tr("Bits (Kbps, Mbps)", "比特 (Kbps, Mbps)"), value: "bits" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_networkUnit)
        }

        QQC2.CheckBox {
            id: noiseCheck
            Kirigami.FormData.label: page.tr("Idle filter:", "静默过滤：")
            enabled: enabledCheck.checked
            text: page.tr("Show 0 when traffic < 1 KB/s", "流量低于 1 KB/s 时显示为 0")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("Popover & Colors", "弹窗与配色")
        }

        QQC2.CheckBox {
            id: connInfoCheck
            Kirigami.FormData.label: page.tr("Sections:", "详情卡片：")
            enabled: enabledCheck.checked
            text: page.tr("Show IP, gateway & traffic totals", "显示 IP、网关与累计流量")
        }

        QQC2.CheckBox {
            id: topProcCheck
            enabled: enabledCheck.checked
            text: page.tr("Show active network processes", "显示活跃网络进程 (连接数)")
        }

        ColorSwatchPicker {
            id: downColorPicker
            Kirigami.FormData.label: page.tr("Download:", "下载颜色：")
        }

        ColorSwatchPicker {
            id: upColorPicker
            Kirigami.FormData.label: page.tr("Upload:", "上传颜色：")
        }
    }
}
