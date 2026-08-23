import QtQuick

Rectangle {
    property string label: ""
    property real value: 0      // Used 'real' instead of 'float'
    property real maxValue: 100 // Used 'real' instead of 'float'
    property string unit: ""
    property color barColor: "white"

    width: 60
    height: 180
    color: "transparent"

    Column {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            width: 30
            height: 120
            color: "#1a1a1a"
            radius: 6
            anchors.horizontalCenter: parent
            clip: true

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.min(parent.height, (value / maxValue) * parent.height)
                color: barColor
                radius: 6
                
                Behavior on height {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            text: value.toFixed(1) + unit
            color: "white"
            font.pixelSize: 14
            anchors.horizontalCenter: parent
        }

        Text {
            text: label
            color: "#666666"
            font.pixelSize: 12
            font.bold: true
            anchors.horizontalCenter: parent
        }
    }
}
