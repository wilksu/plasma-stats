import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

import "../I18n.js" as I18n

KCM.SimpleKCM {
    id: page

    property alias cfg_language: langCombo.currentValue
    property string cfg_moduleOrder: "cpu,gpu,ram,network"
    property alias cfg_refreshIntervalMs: refreshCombo.currentValue
    property alias cfg_colorSchemeMode: colorModeCombo.currentValue
    property alias cfg_temperatureUnit: tempUnitCombo.currentValue
    property alias cfg_panelDensity: densityCombo.currentValue
    property alias cfg_showModuleLabels: labelsCheck.checked
    property alias cfg_useMonospaceNumbers: monoCheck.checked

    readonly property string lang: langCombo.currentValue || Plasmoid.configuration.language || "auto"
    function tr(en, zh) { return I18n.tr(en, zh, lang) }

    property var orderList: (cfg_moduleOrder || "cpu,gpu,ram,network").split(",").filter(function(s) { return s.length > 0 })

    function moveModule(index, delta) {
        var nextIdx = index + delta
        if (nextIdx < 0 || nextIdx >= orderList.length) return
        var copy = orderList.slice()
        var tmp = copy[index]
        copy[index] = copy[nextIdx]
        copy[nextIdx] = tmp
        orderList = copy
        cfg_moduleOrder = copy.join(",")
    }

    function moduleDisplayName(id) {
        if (id === "cpu") return "CPU"
        if (id === "gpu") return "GPU"
        if (id === "ram") return tr("RAM (Memory)", "RAM (内存)")
        if (id === "network") return tr("Network", "网络")
        return id
    }

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("General", "基础设置")
        }

        QQC2.ComboBox {
            id: langCombo
            Kirigami.FormData.label: page.tr("Language:", "界面语言：")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: page.tr("Follow System (Auto)", "跟随系统 (自动)"), value: "auto" },
                { text: "简体中文", value: "zh_CN" },
                { text: "English", value: "en_US" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_language)
        }

        QQC2.ComboBox {
            id: refreshCombo
            Kirigami.FormData.label: page.tr("Update interval:", "刷新频率：")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: page.tr("0.5 sec (Fast)", "0.5 秒 (高频)"), value: 500 },
                { text: page.tr("1 sec (Default)", "1 秒 (默认)"), value: 1000 },
                { text: page.tr("2 sec", "2 秒"), value: 2000 },
                { text: page.tr("3 sec", "3 秒"), value: 3000 },
                { text: page.tr("5 sec (Low power)", "5 秒 (省电)"), value: 5000 }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_refreshIntervalMs)
        }

        QQC2.ComboBox {
            id: tempUnitCombo
            Kirigami.FormData.label: page.tr("Temperature:", "温度单位：")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: page.tr("Celsius (°C)", "摄氏度 (°C)"), value: "C" },
                { text: page.tr("Fahrenheit (°F)", "华氏度 (°F)"), value: "F" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_temperatureUnit)
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("Panel Appearance", "顶栏外观")
        }

        QQC2.ComboBox {
            id: colorModeCombo
            Kirigami.FormData.label: page.tr("Color scheme:", "配色模式：")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: page.tr("Module Accent (Default)", "模块主题色 (默认)"), value: "accent" },
                { text: page.tr("Dynamic by Load", "按负载动态变色"), value: "load" },
                { text: page.tr("Monochrome", "极简单色"), value: "monochrome" },
                { text: page.tr("Custom per Module", "各模块自定义颜色"), value: "custom" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_colorSchemeMode)
        }

        QQC2.ComboBox {
            id: densityCombo
            Kirigami.FormData.label: page.tr("Spacing density:", "排列密度：")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: page.tr("Compact", "紧凑"), value: "compact" },
                { text: page.tr("Normal", "标准"), value: "normal" },
                { text: page.tr("Relaxed", "宽松"), value: "relaxed" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_panelDensity)
        }

        QQC2.CheckBox {
            id: labelsCheck
            Kirigami.FormData.label: page.tr("Labels:", "文字标签：")
            text: page.tr("Show module title & percentage", "显示模块名称与百分比")
        }

        QQC2.CheckBox {
            id: monoCheck
            Kirigami.FormData.label: page.tr("Typography:", "数字对齐：")
            text: page.tr("Tabular monospace digits", "等宽数字 (防止刷新抖动)")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("Modules Overview & Order", "模块总览与顺序")
        }

        ColumnLayout {
            Kirigami.FormData.label: page.tr("Order:", "排列顺序：")
            spacing: 6

            Repeater {
                model: page.orderList
                delegate: RowLayout {
                    required property string modelData
                    required property int index
                    spacing: 8

                    QQC2.Label {
                        text: (index + 1) + ". " + page.moduleDisplayName(modelData)
                        font.weight: Font.DemiBold
                        Layout.minimumWidth: 110
                    }
                    QQC2.Label {
                        readonly property bool isOn: modelData === "cpu" ? Plasmoid.configuration.cpuEnabled
                            : modelData === "gpu" ? Plasmoid.configuration.gpuEnabled
                            : modelData === "ram" ? Plasmoid.configuration.ramEnabled
                            : Plasmoid.configuration.networkEnabled
                        text: isOn ? page.tr("Enabled", "已启用") : page.tr("Disabled", "已停用")
                        font.pixelSize: 11
                        opacity: isOn ? 0.85 : 0.45
                        Layout.minimumWidth: 56
                    }
                    QQC2.ToolButton {
                        icon.name: "go-up"
                        enabled: index > 0
                        onClicked: page.moveModule(index, -1)
                    }
                    QQC2.ToolButton {
                        icon.name: "go-down"
                        enabled: index < page.orderList.length - 1
                        onClicked: page.moveModule(index, 1)
                    }
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: page.tr("About", "关于")
        }

        QQC2.Label {
            Kirigami.FormData.label: "Plasma Stats:"
            text: "v1.0.0  (KDE Plasma 6)"
            opacity: 0.7
        }
    }
}
