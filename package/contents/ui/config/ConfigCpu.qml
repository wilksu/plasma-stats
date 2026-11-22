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

    property alias cfg_cpuEnabled: enabledCheck.checked
    property alias cfg_cpuPanelStyle: styleCombo.currentValue
    property alias cfg_cpuMultiCore: multiCoreCheck.checked
    property alias cfg_cpuShowTemperature: tempCheck.checked
    property alias cfg_cpuShowFrequency: freqCheck.checked
    property alias cfg_cpuTopProcesses: topProcCombo.currentValue
    property alias cfg_cpuShowCoreMatrix: coreMatrixCheck.checked
    property alias cfg_cpuShowSystemInfo: sysInfoCheck.checked
    property alias cfg_cpuCustomColor: colorPicker.selectedColor

    readonly property string lang: Plasmoid.configuration.language || "auto"
    function tr(en, zh) { return I18n.tr(en, zh, lang) }

    Kirigami.FormLayout {
        QQC2.Switch {
            id: enabledCheck
            Kirigami.FormData.label: page.tr("Enable CPU:", "启用 CPU：")
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
                { text: page.tr("Bar Chart", "柱状图"), value: "barchart" },
                { text: page.tr("Line Chart", "折线图"), value: "linechart" },
                { text: page.tr("Label Only", "纯数字"), value: "label" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_cpuPanelStyle)
        }

        QQC2.CheckBox {
            id: multiCoreCheck
            Kirigami.FormData.label: page.tr("Cores:", "核心展示：")
            enabled: enabledCheck.checked && styleCombo.currentValue === "barchart"
            text: page.tr("Split into per-core bars", "按逻辑核心分柱显示")
        }

        QQC2.CheckBox {
            id: tempCheck
            Kirigami.FormData.label: page.tr("Extra info:", "附加信息：")
            enabled: enabledCheck.checked
            text: page.tr("Show temperature", "显示温度")
        }

        QQC2.CheckBox {
            id: freqCheck
            enabled: enabledCheck.checked
            text: page.tr("Show clock frequency", "显示主频")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("Popover & Details", "弹窗与详情")
        }

        QQC2.CheckBox {
            id: coreMatrixCheck
            Kirigami.FormData.label: page.tr("Sections:", "详情卡片：")
            text: page.tr("Show logical cores matrix", "显示逻辑核心柱状矩阵")
        }

        QQC2.CheckBox {
            id: sysInfoCheck
            text: page.tr("Show Linux info (CPU model, governor, uptime)", "显示系统信息 (型号、调频策略、运行时长)")
        }

        QQC2.ComboBox {
            id: topProcCombo
            Kirigami.FormData.label: page.tr("Top processes:", "高占用进程：")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: page.tr("Off", "关闭"), value: 0 },
                { text: "Top 3", value: 3 },
                { text: "Top 5", value: 5 },
                { text: "Top 10", value: 10 }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_cpuTopProcesses)
        }

        ColorSwatchPicker {
            id: colorPicker
            Kirigami.FormData.label: page.tr("Custom color:", "自定义颜色：")
        }
    }
}
