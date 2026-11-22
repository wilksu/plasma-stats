import QtQuick

Canvas {
    id: canvas

    property var values: []
    property real minValue: 0
    property real maxValue: 100
    property color barColor: "#3daee9"
    property color trackColor: Qt.rgba(1, 1, 1, 0.10)
    property real barGap: 1.5
    property real cornerRadius: 1.5
    property bool showTracks: true

    onValuesChanged: requestPaint()
    onBarColorChanged: requestPaint()
    onMaxValueChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var data = values || []
        if (width <= 2 || height <= 2 || data.length === 0) {
            return
        }

        var count = data.length
        var gap = count > 1 ? Math.min(barGap, Math.max(0.5, (width / count) * 0.3)) : 0
        var barW = Math.max(1.5, (width - gap * (count - 1)) / count)
        var range = Math.max(0.0001, maxValue - minValue)

        for (var i = 0; i < count; i++) {
            var x = i * (barW + gap)
            if (showTracks) {
                ctx.fillStyle = trackColor
                ctx.beginPath()
                ctx.roundedRect(x, 0, barW, height, cornerRadius, cornerRadius)
                ctx.fill()
            }

            var v = Math.max(minValue, Math.min(maxValue, Number(data[i]) || 0))
            var ratio = (v - minValue) / range
            var fillH = Math.max(ratio > 0 ? 1.5 : 0, height * ratio)
            if (fillH > 0) {
                ctx.fillStyle = barColor
                ctx.beginPath()
                ctx.roundedRect(x, height - fillH, barW, fillH, cornerRadius, cornerRadius)
                ctx.fill()
            }
        }
    }
}
