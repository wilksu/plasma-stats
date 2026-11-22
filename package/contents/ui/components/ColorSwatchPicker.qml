import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: picker

    property string selectedColor: "#3daee9"
    readonly property var presets: [
        "#3daee9", // KDE / Sky Blue
        "#007aff", // macOS Blue
        "#2ecc71", // Emerald Green
        "#9b59b6", // Purple
        "#f39c12", // Amber
        "#e74c3c", // Coral Red
        "#1abc9c", // Teal
        "#e84393"  // Pink
    ]

    spacing: 6

    Repeater {
        model: picker.presets
        delegate: Rectangle {
            required property string modelData
            width: 22
            height: 22
            radius: 11
            color: modelData
            border.width: picker.selectedColor.toLowerCase() === modelData.toLowerCase() ? 2 : 1
            border.color: picker.selectedColor.toLowerCase() === modelData.toLowerCase()
                ? Kirigami.Theme.textColor
                : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: picker.selectedColor = modelData
            }
        }
    }

    QQC2.TextField {
        text: picker.selectedColor
        implicitWidth: 82
        font.pixelSize: 11
        placeholderText: "#3daee9"
        onTextEdited: {
            if (/^#[0-9a-fA-F]{6}$/.test(text)) {
                picker.selectedColor = text
            }
        }
    }
}
