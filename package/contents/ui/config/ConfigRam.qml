import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

import "../I18n.js" as I18n
import "../components"

KCM.SimpleKCM {
    id: page

    property alias cfg_ramEnabled: enabledCheck.checked
    property alias cfg_ramPanelStyle: styleCombo.currentValue
    property alias cfg_ramDisplayFormat: formatCombo.currentValue
    property alias cfg_ramShowSwap: swapCheck.checked
    property alias cfg_ramShowTopProcesses: topProcCheck.checked
    property alias cfg_ramCustomColor: colorPicker.selectedColor

    readonly property string lang: Plasmoid.configuration.language || "auto"
    function tr(en, zh) { return I18n.tr(en, zh, lang) }

    Kirigami.FormLayout {
        QQC2.Switch {
            id: enabledCheck
            Kirigami.FormData.label: page.tr("Enable RAM:", "启用内存：")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("Panel Widget", "顶栏小部件")
        }

        QQC2.ComboBox {
            id: styleCombo
            Kirigami.FormData.label: page.tr("Widget style:", "显示样式：")
            enabled: enabledCheck.checked
            textRole: "text"
            valueRole: "value"
            model: [
                { text: page.tr("Ring / Pie Chart", "环形 / 饼图"), value: "pie" },
                { text: page.tr("Bar Chart", "柱状图"), value: "barchart" },
                { text: page.tr("Label Only", "纯数字"), value: "label" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_ramPanelStyle)
        }

        QQC2.ComboBox {
            id: formatCombo
            Kirigami.FormData.label: page.tr("Value format:", "数值格式：")
            enabled: enabledCheck.checked
            textRole: "text"
            valueRole: "value"
            model: [
                { text: page.tr("Percentage (%)", "百分比 (%)"), value: "percent" },
                { text: page.tr("Used Gigabytes (GB)", "已用容量 (GB)"), value: "gb" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_ramDisplayFormat)
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("Popover & Color", "弹窗与配色")
        }

        QQC2.CheckBox {
            id: swapCheck
            Kirigami.FormData.label: page.tr("Sections:", "详情卡片：")
            enabled: enabledCheck.checked
            text: page.tr("Show Swap usage", "显示 Swap 交换分区")
        }

        QQC2.CheckBox {
            id: topProcCheck
            enabled: enabledCheck.checked
            text: page.tr("Show top memory processes", "显示高内存占用进程")
        }

        ColorSwatchPicker {
            id: colorPicker
            Kirigami.FormData.label: page.tr("Custom color:", "自定义颜色：")
        }
    }
}
