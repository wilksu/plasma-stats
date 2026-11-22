import QtQuick

Canvas {
    id: canvas

    property var primaryValues: []
    property var secondaryValues: []
    property color primaryColor: "#3498db"
    property color secondaryColor: "#e74c3c"
    property real lineWidth: 1.5
    property real minScaleMax: 10240 // 10 KB/s floor so idle noise doesn't look huge

    onPrimaryValuesChanged: requestPaint()
    onSecondaryValuesChanged: requestPaint()
    onPrimaryColorChanged: requestPaint()
    onSecondaryColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        if (width <= 2 || height <= 2) {
            return
        }

        var d1 = primaryValues || []
        var d2 = secondaryValues || []
        var maxLen = Math.max(d1.length, d2.length)
        if (maxLen < 2) {
            return
        }

        var peak = minScaleMax
        for (var i = 0; i < d1.length; i++) {
            var v1 = Number(d1[i]) || 0
            if (v1 > peak) peak = v1
        }
        for (var j = 0; j < d2.length; j++) {
            var v2 = Number(d2[j]) || 0
            if (v2 > peak) peak = v2
        }

        var padY = Math.max(1, lineWidth)
        var drawH = Math.max(1, height - padY * 2)

        function drawSeries(data, color) {
            if (data.length < 2) return
            var stepX = width / Math.max(1, data.length - 1)
            ctx.beginPath()
            for (var k = 0; k < data.length; k++) {
                var val = Math.max(0, Number(data[k]) || 0)
                var x = k * stepX
                var y = padY + drawH * (1.0 - Math.min(1.0, val / peak))
                if (k === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.strokeStyle = color
            ctx.lineWidth = lineWidth
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.stroke()
        }

        drawSeries(d2, secondaryColor)
        drawSeries(d1, primaryColor)
    }
}
