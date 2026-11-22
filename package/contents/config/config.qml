import QtQuick
import org.kde.plasma.configuration
import org.kde.plasma.plasmoid
import "../ui/I18n.js" as I18n

ConfigModel {
    readonly property string lang: Plasmoid.configuration.language || "auto"

    ConfigCategory {
        name: I18n.tr("General", "通用", lang)
        icon: "configure"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: "CPU"
        icon: "cpu"
        source: "config/ConfigCpu.qml"
    }
    ConfigCategory {
        name: "GPU"
        icon: "video-display"
        source: "config/ConfigGpu.qml"
    }
    ConfigCategory {
        name: I18n.tr("RAM", "内存", lang)
        icon: "memory"
        source: "config/ConfigRam.qml"
    }
    ConfigCategory {
        name: I18n.tr("Network", "网络", lang)
        icon: "network-wired"
        source: "config/ConfigNetwork.qml"
    }
}
