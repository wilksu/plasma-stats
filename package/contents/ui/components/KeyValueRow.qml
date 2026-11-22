import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: rowRoot

    property string label: ""
    property string value: ""
    property color valueColor: Kirigami.Theme.textColor
    property color dotColor: "transparent"
    property bool showDot: false
    property bool showDivider: true

    Layout.fillWidth: true
    spacing: 3

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Rectangle {
            visible: rowRoot.showDot
            width: 7
            height: 7
            radius: 3.5
            color: rowRoot.dotColor
        }

        PlasmaComponents.Label {
            text: rowRoot.label
            font.pixelSize: 11
            opacity: 0.72
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        PlasmaComponents.Label {
            text: rowRoot.value
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.features: ({ "tnum": 1 })
            color: rowRoot.valueColor
        }
    }

    Rectangle {
        visible: rowRoot.showDivider
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
    }
}
