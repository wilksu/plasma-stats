import QtQuick

Canvas {
    id: canvas

    property var values: []
    property real minValue: 0
    property real maxValue: 100
    property color lineColor: "#3daee9"
    property real fillOpacity: 0.24
    property real lineWidth: 1.6
    property bool showBaseline: false
    property bool showGrid: false
    property color gridColor: Qt.rgba(1, 1, 1, 0.08)

    onValuesChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onMaxValueChanged: requestPaint()
    onShowGridChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        if (width <= 2 || height <= 2) {
            return
        }

        if (showGrid) {
            ctx.strokeStyle = gridColor
            ctx.lineWidth = 1
            var ys = [height * 0.25, height * 0.5, height * 0.75]
            for (var g = 0; g < ys.length; g++) {
                ctx.beginPath()
                ctx.moveTo(0, Math.round(ys[g]) + 0.5)
                ctx.lineTo(width, Math.round(ys[g]) + 0.5)
                ctx.stroke()
            }
        }

        if (showBaseline) {
            ctx.strokeStyle = gridColor
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(0, height - 0.5)
            ctx.lineTo(width, height - 0.5)
            ctx.stroke()
        }

        var data = values || []
        if (data.length < 2) {
            return
        }

        var range = Math.max(0.0001, maxValue - minValue)
        var padY = Math.max(1.5, lineWidth)
        var drawH = Math.max(1, height - padY * 2)
        var stepX = width / Math.max(1, data.length - 1)

        function yFor(v) {
            var clamped = Math.max(minValue, Math.min(maxValue, Number(v) || 0))
            var ratio = (clamped - minValue) / range
            return padY + drawH * (1.0 - ratio)
        }

        if (fillOpacity > 0) {
            var grad = ctx.createLinearGradient(0, 0, 0, height)
            grad.addColorStop(0, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, fillOpacity))
            grad.addColorStop(1, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.01))

            ctx.beginPath()
            ctx.moveTo(0, height)
            for (var i = 0; i < data.length; i++) {
                ctx.lineTo(i * stepX, yFor(data[i]))
            }
            ctx.lineTo((data.length - 1) * stepX, height)
            ctx.closePath()
            ctx.fillStyle = grad
            ctx.fill()
        }

        ctx.beginPath()
        for (var j = 0; j < data.length; j++) {
            var x = j * stepX
            var y = yFor(data[j])
            if (j === 0) {
                ctx.moveTo(x, y)
            } else {
                var prevX = (j - 1) * stepX
                var prevY = yFor(data[j - 1])
                var midX = (prevX + x) / 2
                ctx.bezierCurveTo(midX, prevY, midX, y, x, y)
            }
        }
        ctx.strokeStyle = lineColor
        ctx.lineWidth = lineWidth
        ctx.lineJoin = "round"
        ctx.lineCap = "round"
        ctx.stroke()
    }
}
