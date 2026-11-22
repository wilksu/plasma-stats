.pragma library

function isChinese(langSetting) {
    if (langSetting === "zh_CN") return true
    if (langSetting === "en_US") return false
    var loc = Qt.locale().name || ""
    return loc.toLowerCase().indexOf("zh") === 0
}

function tr(en, zh, langSetting) {
    return isChinese(langSetting) ? zh : en
}
