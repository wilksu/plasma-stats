import QtQuick

Canvas {
    id: canvas

    property real value: 0
    property real maxValue: 100
    property color ringColor: "#9b59b6"
    property color trackColor: Qt.rgba(1, 1, 1, 0.12)
    property real lineWidth: 3.0
    property bool filledPie: false
    property var segments: [] // Optional: [{ value: number, color: color }]

    onValueChanged: requestPaint()
    onMaxValueChanged: requestPaint()
    onRingColorChanged: requestPaint()
    onSegmentsChanged: requestPaint()
    onFilledPieChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var size = Math.min(width, height)
        if (size <= 4) {
            return
        }

        var cx = width / 2
        var cy = height / 2
        var startAngle = -Math.PI / 2

        if (filledPie) {
            var ratio = Math.max(0, Math.min(1, maxValue > 0 ? (value / maxValue) : 0))
            var rPie = size / 2 - 1
            ctx.beginPath()
            ctx.arc(cx, cy, rPie, 0, Math.PI * 2)
            ctx.fillStyle = trackColor
            ctx.fill()

            if (ratio > 0) {
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.arc(cx, cy, rPie, startAngle, startAngle + Math.PI * 2 * ratio)
                ctx.closePath()
                ctx.fillStyle = ringColor
                ctx.fill()
            }
            return
        }

        var lw = Math.min(lineWidth, size / 3)
        var r = size / 2 - lw / 2 - 0.5

        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.strokeStyle = trackColor
        ctx.lineWidth = lw
        ctx.stroke()

        if (segments && segments.length > 0) {
            var curAngle = startAngle
            for (var i = 0; i < segments.length; i++) {
                var seg = segments[i]
                var segVal = Math.max(0, Number(seg.value) || 0)
                if (segVal <= 0 || maxValue <= 0) continue
                var segAngle = Math.PI * 2 * Math.min(1, segVal / maxValue)
                ctx.beginPath()
                ctx.arc(cx, cy, r, curAngle, curAngle + segAngle)
                ctx.strokeStyle = seg.color || ringColor
                ctx.lineWidth = lw
                ctx.lineCap = "butt"
                ctx.stroke()
                curAngle += segAngle
            }
        } else {
            var singleRatio = Math.max(0, Math.min(1, maxValue > 0 ? (value / maxValue) : 0))
            if (singleRatio > 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, r, startAngle, startAngle + Math.PI * 2 * singleRatio)
                ctx.strokeStyle = ringColor
                ctx.lineWidth = lw
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
    }
}
