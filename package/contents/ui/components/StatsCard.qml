import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: card

    default property alias content: innerLayout.data
    property int padding: 10
    property int spacing: 6

    Layout.fillWidth: true
    implicitHeight: innerLayout.implicitHeight + padding * 2
    radius: 10
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.045)
    border.width: 1
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

    ColumnLayout {
        id: innerLayout
        anchors.fill: parent
        anchors.margins: card.padding
        spacing: card.spacing
    }
}
