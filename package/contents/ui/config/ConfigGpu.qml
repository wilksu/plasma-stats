import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import org.kde.ksysguard.sensors as Sensors

import "../I18n.js" as I18n
import "../components"

KCM.SimpleKCM {
    id: page

    property alias cfg_gpuEnabled: enabledCheck.checked
    property string cfg_gpuTarget: "auto"
    property alias cfg_gpuPanelStyle: styleCombo.currentValue
    property alias cfg_gpuShowVram: vramCheck.checked
    property alias cfg_gpuShowTemperature: tempCheck.checked
    property alias cfg_gpuCustomColor: colorPicker.selectedColor

    readonly property string lang: Plasmoid.configuration.language || "auto"
    function tr(en, zh) { return I18n.tr(en, zh, lang) }

    Sensors.Sensor { id: gpuProbe0; sensorId: "gpu/gpu0/usage"; updateRateLimit: 5000 }
    Sensors.Sensor { id: gpuProbe1; sensorId: "gpu/gpu1/usage"; updateRateLimit: 5000 }
    Sensors.Sensor { id: gpuProbe2; sensorId: "gpu/gpu2/usage"; updateRateLimit: 5000 }
    Sensors.Sensor { id: gpuProbe3; sensorId: "gpu/gpu3/usage"; updateRateLimit: 5000 }

    readonly property var gpuChoices: {
        var list = [
            { text: page.tr("Auto (Most Active)", "自动 (最活跃显卡)"), value: "auto" },
            { text: page.tr("All GPUs Combined", "全部显卡合并"), value: "all" }
        ]
        var probes = [
            { id: "gpu0", s: gpuProbe0 },
            { id: "gpu1", s: gpuProbe1 },
            { id: "gpu2", s: gpuProbe2 },
            { id: "gpu3", s: gpuProbe3 }
        ]
        var seen = {}
        for (var i = 0; i < probes.length; i++) {
            if (probes[i].s.status === Sensors.Sensor.Ready) {
                seen[probes[i].id] = true
                list.push({ text: probes[i].id.toUpperCase(), value: probes[i].id })
            }
        }
        if (!seen["gpu0"]) list.push({ text: "GPU0 (gpu0)", value: "gpu0" })
        if (!seen["gpu1"]) list.push({ text: "GPU1 (gpu1)", value: "gpu1" })
        return list
    }

    Kirigami.FormLayout {
        QQC2.Switch {
            id: enabledCheck
            Kirigami.FormData.label: page.tr("Enable GPU:", "启用 GPU：")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("Panel Widget", "顶栏小部件")
        }

        QQC2.ComboBox {
            id: targetCombo
            Kirigami.FormData.label: page.tr("Target GPU:", "目标显卡：")
            enabled: enabledCheck.checked
            textRole: "text"
            valueRole: "value"
            model: page.gpuChoices
            onActivated: page.cfg_gpuTarget = currentValue
            Component.onCompleted: {
                var idx = indexOfValue(page.cfg_gpuTarget)
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
                { text: page.tr("Line Chart", "折线图"), value: "linechart" },
                { text: page.tr("Bar Chart", "柱状图"), value: "barchart" },
                { text: page.tr("Label Only", "纯数字"), value: "label" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_gpuPanelStyle)
        }

        QQC2.CheckBox {
            id: tempCheck
            Kirigami.FormData.label: page.tr("Extra info:", "附加信息：")
            enabled: enabledCheck.checked
            text: page.tr("Show temperature", "显示温度")
        }

        QQC2.CheckBox {
            id: vramCheck
            enabled: enabledCheck.checked
            text: page.tr("Show VRAM usage", "显示显存占用")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("Color", "配色")
        }

        ColorSwatchPicker {
            id: colorPicker
            Kirigami.FormData.label: page.tr("Custom color:", "自定义颜色：")
        }
    }
}
