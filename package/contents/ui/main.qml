import QtQuick
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.ksysguard.process as Process
import org.kde.plasma.plasma5support as Plasma5Support

import "I18n.js" as I18n

PlasmoidItem {
    id: root

    function tr(en, zh) {
        return I18n.tr(en, zh, Plasmoid.configuration.language)
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    // Which detail tab is active in the popover
    property string activeTab: "cpu"

    // Config shortcuts
    readonly property int refreshMs: Math.max(500, Plasmoid.configuration.refreshIntervalMs)
    readonly property int historyLen: 45
    readonly property string colorMode: Plasmoid.configuration.colorSchemeMode
    readonly property string tempUnit: Plasmoid.configuration.temperatureUnit
    readonly property int noiseThresholdBytes: 1024

    readonly property var orderedModules: {
        var raw = (Plasmoid.configuration.moduleOrder || "cpu,gpu,ram,network").split(",")
        var valid = ["cpu", "gpu", "ram", "network"]
        var result = []
        for (var i = 0; i < raw.length; i++) {
            var m = raw[i].trim()
            if (valid.indexOf(m) !== -1 && result.indexOf(m) === -1) {
                result.push(m)
            }
        }
        for (var j = 0; j < valid.length; j++) {
            if (result.indexOf(valid[j]) === -1) {
                result.push(valid[j])
            }
        }
        return result
    }

    function isModuleEnabled(mod) {
        if (mod === "cpu") return Plasmoid.configuration.cpuEnabled
        if (mod === "gpu") return Plasmoid.configuration.gpuEnabled
        if (mod === "ram") return Plasmoid.configuration.ramEnabled
        if (mod === "network") return Plasmoid.configuration.networkEnabled
        return false
    }

    function openModule(mod) {
        activeTab = mod
        if (!root.expanded) {
            root.expanded = true
        }
    }

    // -------------------------------------------------------------------------
    // Color & Formatting Helpers
    // -------------------------------------------------------------------------
    function loadColor(percent) {
        if (percent >= 85) return "#e74c3c"
        if (percent >= 65) return "#f39c12"
        return "#2ecc71"
    }

    function moduleColor(mod, percent) {
        if (colorMode === "monochrome") {
            return Kirigami.Theme.textColor
        }
        if (colorMode === "load") {
            return loadColor(percent)
        }
        if (colorMode === "custom") {
            if (mod === "cpu") return Plasmoid.configuration.cpuCustomColor
            if (mod === "gpu") return Plasmoid.configuration.gpuCustomColor
            if (mod === "ram") return Plasmoid.configuration.ramCustomColor
            if (mod === "network") return Plasmoid.configuration.networkDownloadColor
        }
        // Default: "accent" - subtle per-module distinction or theme highlight
        if (mod === "cpu") return Kirigami.Theme.highlightColor
        if (mod === "gpu") return "#2ecc71"
        if (mod === "ram") return "#9b59b6"
        if (mod === "network") return Plasmoid.configuration.networkDownloadColor
        return Kirigami.Theme.highlightColor
    }

    function formatTemp(celsius) {
        if (celsius === undefined || celsius === null || isNaN(celsius) || celsius <= 0) {
            return "--"
        }
        if (tempUnit === "F") {
            return Math.round(celsius * 9 / 5 + 32) + "°F"
        }
        return Math.round(celsius) + "°C"
    }

    function formatBytes(bytes, decimals) {
        var dec = decimals !== undefined ? decimals : 1
        var b = Number(bytes) || 0
        if (b <= 0) return "0 B"
        var units = ["B", "KB", "MB", "GB", "TB"]
        var idx = Math.min(units.length - 1, Math.floor(Math.log(b) / Math.log(1024)))
        var val = b / Math.pow(1024, idx)
        return (idx === 0 ? Math.round(val) : val.toFixed(dec)) + " " + units[idx]
    }

    function formatSpeed(bytesPerSec, compact) {
        var bps = Number(bytesPerSec) || 0
        if (Plasmoid.configuration.networkHideNoise && bps < root.noiseThresholdBytes) {
            bps = 0
        }
        var useBits = (Plasmoid.configuration.networkUnit === "bits")
        var val = useBits ? bps * 8 : bps
        var divisor = useBits ? 1000 : 1024
        var units = useBits
            ? (compact ? ["b", "K", "M", "G"] : ["bps", "Kbps", "Mbps", "Gbps"])
            : (compact ? ["B", "K", "M", "G"] : ["B/s", "KB/s", "MB/s", "GB/s"])

        if (val <= 0) {
            return compact ? ("0" + units[1]) : ("0 " + units[1])
        }
        var idx = Math.min(units.length - 1, Math.floor(Math.log(val) / Math.log(divisor)))
        var scaled = val / Math.pow(divisor, idx)
        if (compact) {
            var rounded = Math.round(scaled)
            if (rounded >= 1000 && idx < units.length - 1) {
                idx += 1
                rounded = Math.round(scaled / divisor)
            }
            return Math.min(999, rounded).toString() + units[idx]
        }
        // Full mode (popover / arrows mode)
        if (scaled >= 999.5 && idx < units.length - 1) {
            idx += 1
            scaled = scaled / divisor
        }
        var text = scaled >= 100 ? Math.round(scaled).toString() : scaled.toFixed(1)
        return text + " " + units[idx]
    }

    function appendHistory(arr, value) {
        var next = arr.slice()
        next.push(value)
        while (next.length > historyLen) {
            next.shift()
        }
        return next
    }

    function sensorNum(sensor, fallback) {
        if (!sensor || sensor.status !== Sensors.Sensor.Ready) return fallback
        if (sensor.value === undefined || sensor.value === null || sensor.value === "") return fallback
        var v = Number(sensor.value)
        return isNaN(v) ? fallback : v
    }

    // -------------------------------------------------------------------------
    // CPU Sensors
    // -------------------------------------------------------------------------
    Sensors.Sensor {
        id: cpuTotalSensor
        sensorId: "cpu/all/usage"
        enabled: Plasmoid.configuration.cpuEnabled
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: cpuUserSensor
        sensorId: "cpu/all/user"
        enabled: Plasmoid.configuration.cpuEnabled && root.expanded
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: cpuSysSensor
        sensorId: "cpu/all/system"
        enabled: Plasmoid.configuration.cpuEnabled && root.expanded
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: cpuWaitSensor
        sensorId: "cpu/all/wait"
        enabled: Plasmoid.configuration.cpuEnabled && root.expanded
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: cpuTempSensor
        sensorId: "cpu/all/averageTemperature"
        enabled: Plasmoid.configuration.cpuEnabled && (Plasmoid.configuration.cpuShowTemperature || root.expanded)
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: cpuFreqSensor
        sensorId: "cpu/all/averageFrequency"
        enabled: Plasmoid.configuration.cpuEnabled && (Plasmoid.configuration.cpuShowFrequency || root.expanded)
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: cpuCoreCountSensor
        sensorId: "cpu/all/coreCount"
        enabled: Plasmoid.configuration.cpuEnabled
        updateRateLimit: 10000
    }

    Sensors.SensorDataModel {
        id: cpuCoresModel
        sensors: {
            var count = Math.max(0, Math.min(512, Math.round(root.sensorNum(cpuCoreCountSensor, 0))))
            var ids = []
            for (var i = 0; i < count; i++) ids.push("cpu/cpu" + i + "/usage")
            return ids
        }
        enabled: Plasmoid.configuration.cpuEnabled && (Plasmoid.configuration.cpuMultiCore || root.expanded)
        updateRateLimit: root.refreshMs
    }

    readonly property real cpuUsage: Math.max(0, Math.min(100, sensorNum(cpuTotalSensor, 0)))
    readonly property real cpuUser: Math.max(0, Math.min(100, sensorNum(cpuUserSensor, 0)))
    readonly property real cpuSystem: Math.max(0, Math.min(100, sensorNum(cpuSysSensor, 0)))
    readonly property real cpuIowait: Math.max(0, Math.min(100, sensorNum(cpuWaitSensor, 0)))
    readonly property real cpuTempC: sensorNum(cpuTempSensor, 0)
    readonly property real cpuFreqMHz: sensorNum(cpuFreqSensor, 0)
    readonly property int cpuCoreCount: Math.max(cpuCoresModel.columnCount(), Math.round(sensorNum(cpuCoreCountSensor, 0)))
    property var cpuCoreUsages: []
    property var cpuHistory: [0, 0]

    // -------------------------------------------------------------------------
    // GPU Sensors & Discovery (probe gpu0..gpu3 directly via Sensors.Sensor)
    // -------------------------------------------------------------------------
    property var discoveredGpus: []
    property string autoGpuId: "all"
    property real discoveredGpuUsage: -1

    Sensors.Sensor { id: gpuProbe0; sensorId: "gpu/gpu0/usage"; enabled: Plasmoid.configuration.gpuEnabled; updateRateLimit: root.refreshMs; onStatusChanged: root.refreshGpuDiscovery(); onValueChanged: root.refreshGpuDiscovery() }
    Sensors.Sensor { id: gpuProbe1; sensorId: "gpu/gpu1/usage"; enabled: Plasmoid.configuration.gpuEnabled; updateRateLimit: root.refreshMs; onStatusChanged: root.refreshGpuDiscovery(); onValueChanged: root.refreshGpuDiscovery() }
    Sensors.Sensor { id: gpuProbe2; sensorId: "gpu/gpu2/usage"; enabled: Plasmoid.configuration.gpuEnabled; updateRateLimit: 5000; onStatusChanged: root.refreshGpuDiscovery() }
    Sensors.Sensor { id: gpuProbe3; sensorId: "gpu/gpu3/usage"; enabled: Plasmoid.configuration.gpuEnabled; updateRateLimit: 5000; onStatusChanged: root.refreshGpuDiscovery() }

    function refreshGpuDiscovery() {
        var probes = [
            { id: "gpu0", sensor: gpuProbe0 },
            { id: "gpu1", sensor: gpuProbe1 },
            { id: "gpu2", sensor: gpuProbe2 },
            { id: "gpu3", sensor: gpuProbe3 }
        ]
        var list = []
        var bestId = ""
        var bestVal = -1
        var currentVal = -1
        var usageMap = {}

        for (var i = 0; i < probes.length; i++) {
            var p = probes[i]
            if (p.sensor.status === Sensors.Sensor.Ready) {
                list.push(p.id)
                var val = Number(p.sensor.value)
                if (isNaN(val)) val = 0
                usageMap[p.id] = val
                if (p.id === autoGpuId) currentVal = val
                if (val > bestVal) {
                    bestVal = val
                    bestId = p.id
                }
            }
        }
        discoveredGpus = list

        if (list.length === 0) {
            autoGpuId = "all"
            discoveredGpuUsage = -1
            return
        }

        // Sticky selection: prefer last/active GPU on initial discovery, switch only if another is busier
        if (list.indexOf(autoGpuId) === -1) {
            autoGpuId = (bestVal > 0 && bestId) ? bestId : list[list.length - 1]
        } else if (bestId && bestId !== autoGpuId && bestVal > Math.max(2, currentVal + 3)) {
            autoGpuId = bestId
        }

        var target = Plasmoid.configuration.gpuTarget || "auto"
        var activeId = (target === "auto") ? autoGpuId : target
        discoveredGpuUsage = (usageMap[activeId] !== undefined) ? usageMap[activeId] : -1
    }

    readonly property string resolvedGpuId: {
        var target = Plasmoid.configuration.gpuTarget || "auto"
        if (target === "all") return "all"
        if (target !== "auto") return target
        return root.autoGpuId || "all"
    }

    Sensors.Sensor {
        id: gpuUsageSensor
        sensorId: "gpu/" + root.resolvedGpuId + "/usage"
        enabled: Plasmoid.configuration.gpuEnabled
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: gpuTempSensor
        sensorId: "gpu/" + root.resolvedGpuId + "/temperature"
        enabled: Plasmoid.configuration.gpuEnabled && (Plasmoid.configuration.gpuShowTemperature || root.expanded)
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: gpuUsedVramSensor
        sensorId: "gpu/" + root.resolvedGpuId + "/usedVram"
        enabled: Plasmoid.configuration.gpuEnabled && (Plasmoid.configuration.gpuShowVram || root.expanded)
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: gpuTotalVramSensor
        sensorId: "gpu/" + root.resolvedGpuId + "/totalVram"
        enabled: Plasmoid.configuration.gpuEnabled && (Plasmoid.configuration.gpuShowVram || root.expanded)
        updateRateLimit: 10000
    }
    Sensors.Sensor {
        id: gpuPowerSensor
        sensorId: "gpu/" + root.resolvedGpuId + "/power"
        enabled: Plasmoid.configuration.gpuEnabled && root.expanded
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: gpuFreqSensor
        sensorId: "gpu/" + root.resolvedGpuId + "/coreFrequency"
        enabled: Plasmoid.configuration.gpuEnabled && root.expanded
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: gpuNameSensor
        sensorId: "gpu/" + root.resolvedGpuId + "/name"
        enabled: Plasmoid.configuration.gpuEnabled && root.expanded
        updateRateLimit: 30000
    }

    readonly property real gpuUsage: Math.max(0, Math.min(100, (root.resolvedGpuId !== "all" && root.discoveredGpuUsage >= 0) ? root.discoveredGpuUsage : sensorNum(gpuUsageSensor, 0)))
    readonly property real gpuTempC: sensorNum(gpuTempSensor, 0)
    readonly property real gpuUsedVramBytes: Math.max(0, sensorNum(gpuUsedVramSensor, 0))
    readonly property real gpuTotalVramBytes: Math.max(0, sensorNum(gpuTotalVramSensor, 0))
    readonly property real gpuVramPercent: gpuTotalVramBytes > 0 ? Math.min(100, (gpuUsedVramBytes / gpuTotalVramBytes) * 100) : 0
    readonly property real gpuPowerW: sensorNum(gpuPowerSensor, 0)
    readonly property real gpuFreqMHz: sensorNum(gpuFreqSensor, 0)
    readonly property string gpuName: (gpuNameSensor.status === Sensors.Sensor.Ready && gpuNameSensor.value) ? String(gpuNameSensor.value) : root.resolvedGpuId.toUpperCase()
    property var gpuHistory: [0, 0]

    // -------------------------------------------------------------------------
    // RAM Sensors
    // -------------------------------------------------------------------------
    Sensors.Sensor {
        id: ramTotalSensor
        sensorId: "memory/physical/total"
        enabled: Plasmoid.configuration.ramEnabled
        updateRateLimit: 10000
    }
    Sensors.Sensor {
        id: ramUsedSensor
        sensorId: "memory/physical/used"
        enabled: Plasmoid.configuration.ramEnabled
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: ramFreeSensor
        sensorId: "memory/physical/free"
        enabled: Plasmoid.configuration.ramEnabled && root.expanded
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: ramCacheSensor
        sensorId: "memory/physical/cache"
        enabled: Plasmoid.configuration.ramEnabled && root.expanded
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: ramBufferSensor
        sensorId: "memory/physical/buffer"
        enabled: Plasmoid.configuration.ramEnabled && root.expanded
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: ramPercentSensor
        sensorId: "memory/physical/usedPercent"
        enabled: Plasmoid.configuration.ramEnabled
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: swapTotalSensor
        sensorId: "memory/swap/total"
        enabled: Plasmoid.configuration.ramEnabled && (Plasmoid.configuration.ramShowSwap || root.expanded)
        updateRateLimit: 10000
    }
    Sensors.Sensor {
        id: swapUsedSensor
        sensorId: "memory/swap/used"
        enabled: Plasmoid.configuration.ramEnabled && (Plasmoid.configuration.ramShowSwap || root.expanded)
        updateRateLimit: root.refreshMs
    }

    readonly property real ramTotalBytes: Math.max(0, sensorNum(ramTotalSensor, 0))
    readonly property real ramUsedBytes: Math.max(0, sensorNum(ramUsedSensor, 0))
    readonly property real ramAvailableBytes: ramTotalBytes > 0 ? Math.max(0, ramTotalBytes - ramUsedBytes) : Math.max(0, sensorNum(ramFreeSensor, 0))
    readonly property real ramFreeBytes: ramAvailableBytes
    readonly property real ramCacheBytes: Math.max(0, sensorNum(ramCacheSensor, 0))
    readonly property real ramBufferBytes: Math.max(0, sensorNum(ramBufferSensor, 0))
    readonly property real ramPercent: {
        var p = sensorNum(ramPercentSensor, -1)
        if (p > 0) return Math.min(100, p)
        if (ramTotalBytes > 0 && ramUsedBytes > 0) {
            return Math.min(100, (ramUsedBytes / ramTotalBytes) * 100)
        }
        return p >= 0 ? Math.min(100, p) : 0
    }
    readonly property real swapTotalBytes: Math.max(0, sensorNum(swapTotalSensor, 0))
    readonly property real swapUsedBytes: Math.max(0, sensorNum(swapUsedSensor, 0))
    readonly property real swapPercent: swapTotalBytes > 0 ? Math.min(100, (swapUsedBytes / swapTotalBytes) * 100) : 0
    property var ramHistory: [0, 0]

    // -------------------------------------------------------------------------
    // Network Sensors & Discovery
    // -------------------------------------------------------------------------
    property var discoveredNetInterfaces: []

    Plasma5Support.DataSource {
        id: netIfacesSource
        engine: "executable"
        connectedSources: Plasmoid.configuration.networkEnabled ? ["ls -1 /sys/class/net"] : []
        interval: 30000
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
            root.discoveredNetInterfaces = list
        }
    }

    readonly property string resolvedNetIface: {
        var cfg = (Plasmoid.configuration.networkInterface || "all").trim()
        return cfg.length > 0 ? cfg : "all"
    }

    Sensors.Sensor {
        id: netDownSensor
        sensorId: "network/" + root.resolvedNetIface + "/download"
        enabled: Plasmoid.configuration.networkEnabled
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: netUpSensor
        sensorId: "network/" + root.resolvedNetIface + "/upload"
        enabled: Plasmoid.configuration.networkEnabled
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: netTotalDownSensor
        sensorId: "network/" + root.resolvedNetIface + "/totalDownload"
        enabled: Plasmoid.configuration.networkEnabled && root.expanded
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: netTotalUpSensor
        sensorId: "network/" + root.resolvedNetIface + "/totalUpload"
        enabled: Plasmoid.configuration.networkEnabled && root.expanded
        updateRateLimit: root.refreshMs
    }
    Sensors.Sensor {
        id: netIpv4Sensor
        sensorId: "network/" + (root.resolvedNetIface === "all" && root.netActiveIface !== "--" ? root.netActiveIface : root.resolvedNetIface) + "/ipv4address"
        enabled: Plasmoid.configuration.networkEnabled && root.expanded
        updateRateLimit: 10000
    }

    readonly property real netDownloadBps: Math.max(0, sensorNum(netDownSensor, 0))
    readonly property real netUploadBps: Math.max(0, sensorNum(netUpSensor, 0))
    readonly property real netTotalDownloadBytes: Math.max(0, sensorNum(netTotalDownSensor, 0))
    readonly property real netTotalUploadBytes: Math.max(0, sensorNum(netTotalUpSensor, 0))
    readonly property string netIpv4: (netIpv4Sensor.status === Sensors.Sensor.Ready && netIpv4Sensor.value) ? String(netIpv4Sensor.value) : "--"
    property var netDownloadHistory: [0, 0]
    property var netUploadHistory: [0, 0]
    property real netPeakDownloadBps: 0
    property real netPeakUploadBps: 0

    // -------------------------------------------------------------------------
    // History Sampling Timer
    // -------------------------------------------------------------------------
    Timer {
        id: sampleTimer
        interval: root.refreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (Plasmoid.configuration.cpuEnabled) {
                cpuHistory = appendHistory(cpuHistory, root.cpuUsage)
                var cores = []
                var colCount = cpuCoresModel.columnCount()
                for (var c = 0; c < colCount; c++) {
                    var v = Number(cpuCoresModel.data(cpuCoresModel.index(0, c), Sensors.SensorDataModel.Value))
                    cores.push(isNaN(v) ? 0 : Math.max(0, Math.min(100, v)))
                }
                cpuCoreUsages = cores
            }
            if (Plasmoid.configuration.gpuEnabled) {
                root.refreshGpuDiscovery()
                gpuHistory = appendHistory(gpuHistory, root.gpuUsage)
            }
            if (Plasmoid.configuration.ramEnabled) {
                ramHistory = appendHistory(ramHistory, root.ramPercent)
            }
            if (Plasmoid.configuration.networkEnabled) {
                netDownloadHistory = appendHistory(netDownloadHistory, root.netDownloadBps)
                netUploadHistory = appendHistory(netUploadHistory, root.netUploadBps)
                if (root.netDownloadBps > netPeakDownloadBps) netPeakDownloadBps = root.netDownloadBps
                if (root.netUploadBps > netPeakUploadBps) netPeakUploadBps = root.netUploadBps
            }
            if (root.expanded) {
                root.refreshTopProcessesFromModel()
            }
        }
    }

    // -------------------------------------------------------------------------
    // Native KDE KSysGuard ProcessDataModel (reused from System Monitor)
    // -------------------------------------------------------------------------
    property var topCpuProcesses: []
    property var topRamProcesses: []
    property var topNetProcesses: []
    property string loadAverageText: "--"
    property string cpuModelName: ""
    property string cpuGovernor: "--"
    property string systemUptimeText: "--"
    property string netGateway: "--"
    property string netActiveIface: "--"

    readonly property int topLimit: Math.max(0, Plasmoid.configuration.cpuTopProcesses)

    onExpandedChanged: function() {
        if (root.expanded) {
            Qt.callLater(root.refreshTopProcessesFromModel)
        }
    }

    Process.ProcessDataModel {
        id: nativeProcessModel
        flatList: true
        enabled: root.expanded && (root.topLimit > 0 || Plasmoid.configuration.ramShowTopProcesses || Plasmoid.configuration.networkShowTopProcesses)
        enabledAttributes: {
            var desired = ["name", "pid", "usage", "memory", "netInbound", "netOutbound"]
            var avail = availableAttributes || []
            var out = []
            for (var i = 0; i < desired.length; i++) {
                if (avail.indexOf(desired[i]) !== -1) {
                    out.push(desired[i])
                }
            }
            return out
        }
        onModelReset: root.refreshTopProcessesFromModel()
    }

    function refreshTopProcessesFromModel() {
        var attrs = nativeProcessModel.enabledAttributes || []
        var colName = attrs.indexOf("name")
        var colPid = attrs.indexOf("pid")
        var colUsage = attrs.indexOf("usage")
        var colMem = attrs.indexOf("memory")
        var colNetIn = attrs.indexOf("netInbound")
        var colNetOut = attrs.indexOf("netOutbound")

        if (colName < 0) return

        var rows = nativeProcessModel.rowCount()
        var all = []
        var totalRam = Math.max(1, root.ramTotalBytes)

        for (var r = 0; r < rows; r++) {
            var pname = nativeProcessModel.data(nativeProcessModel.index(r, colName), Process.ProcessDataModel.Value)
            if (!pname) continue
            var pid = colPid >= 0 ? nativeProcessModel.data(nativeProcessModel.index(r, colPid), Process.ProcessDataModel.Value) : ""
            var cpuVal = colUsage >= 0 ? (Number(nativeProcessModel.data(nativeProcessModel.index(r, colUsage), Process.ProcessDataModel.Value)) || 0) : 0
            var memVal = colMem >= 0 ? (Number(nativeProcessModel.data(nativeProcessModel.index(r, colMem), Process.ProcessDataModel.Value)) || 0) : 0
            var netIn = colNetIn >= 0 ? (Number(nativeProcessModel.data(nativeProcessModel.index(r, colNetIn), Process.ProcessDataModel.Value)) || 0) : 0
            var netOut = colNetOut >= 0 ? (Number(nativeProcessModel.data(nativeProcessModel.index(r, colNetOut), Process.ProcessDataModel.Value)) || 0) : 0

            all.push({
                pid: String(pid),
                name: String(pname),
                cpuNum: cpuVal,
                cpu: cpuVal.toFixed(1),
                memBytes: memVal,
                memNum: (memVal / totalRam) * 100,
                mem: ((memVal / totalRam) * 100).toFixed(1),
                netDown: Math.max(0, netIn),
                netUp: Math.max(0, netOut),
                netTotal: Math.max(0, netIn) + Math.max(0, netOut)
            })
        }

        if (root.topLimit > 0) {
            var byCpu = all.slice().sort(function(a, b) { return b.cpuNum - a.cpuNum })
            root.topCpuProcesses = byCpu.slice(0, root.topLimit)
        } else {
            root.topCpuProcesses = []
        }

        if (Plasmoid.configuration.ramShowTopProcesses) {
            var ramLimit = root.topLimit > 0 ? root.topLimit : 5
            var byRam = all.slice().sort(function(a, b) { return b.memBytes - a.memBytes })
            root.topRamProcesses = byRam.slice(0, ramLimit)
        } else {
            root.topRamProcesses = []
        }

        var byNet = all.filter(function(p) { return p.netTotal > 0 })
                       .sort(function(a, b) { return b.netTotal - a.netTotal })
        root.topNetProcesses = byNet.slice(0, 5)
    }

    // Lightweight Linux host info (loadavg, uptime, governor, CPU model, default route)
    readonly property string procCommand: "sh -c 'cat /proc/loadavg; echo \"---UPTIME---\"; cat /proc/uptime; echo \"---GOV---\"; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo --; echo \"---MODEL---\"; grep -m1 \"model name\" /proc/cpuinfo | cut -d: -f2; echo \"---ROUTE---\"; ip route show default 2>/dev/null | head -n1'"

    function formatUptime(seconds) {
        var s = Math.floor(Number(seconds) || 0)
        if (s <= 0) return "--"
        var d = Math.floor(s / 86400)
        var h = Math.floor((s % 86400) / 3600)
        var m = Math.floor((s % 3600) / 60)
        if (d > 0) return d + "d " + h + "h " + m + "m"
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }

    Plasma5Support.DataSource {
        id: procSource
        engine: "executable"
        connectedSources: root.expanded ? [root.procCommand] : []
        interval: Math.max(3000, root.refreshMs)
        onNewData: function(sourceName, data) {
            if (!data || !data.stdout) return
            var lines = String(data.stdout).split("\n")
            var section = "load"

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (!line) continue
                if (line === "---UPTIME---") { section = "uptime"; continue }
                if (line === "---GOV---") { section = "gov"; continue }
                if (line === "---MODEL---") { section = "model"; continue }
                if (line === "---ROUTE---") { section = "route"; continue }

                if (section === "load") {
                    var lp = line.split(/\s+/)
                    if (lp.length >= 3) {
                        root.loadAverageText = lp[0] + "  " + lp[1] + "  " + lp[2]
                    }
                    section = ""
                } else if (section === "uptime") {
                    var upParts = line.split(/\s+/)
                    if (upParts.length >= 1) root.systemUptimeText = root.formatUptime(upParts[0])
                    section = ""
                } else if (section === "gov") {
                    root.cpuGovernor = line || "--"
                    section = ""
                } else if (section === "model") {
                    root.cpuModelName = line.replace(/\(R\)|\(TM\)|Processor/g, "").replace(/\s+/g, " ").trim()
                    section = ""
                } else if (section === "route") {
                    var viaMatch = line.match(/via\s+(\S+)/)
                    var devMatch = line.match(/dev\s+(\S+)/)
                    root.netGateway = viaMatch ? viaMatch[1] : "--"
                    root.netActiveIface = devMatch ? devMatch[1] : "--"
                    section = ""
                }
            }
        }
    }

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}
}
