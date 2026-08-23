import QtQuick
import QtQuick.Window

Window {
    id: window
    visible: true
    width: 800  // Increased width
    height: 400
    title: "Advanced UGV Telemetry Ground Station"
    color: "#050505"

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        // Top Information Row
        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 20
            text: "SYSTEM READY - LOGGING ACTIVE"
            color: "#444"
            font.pixelSize: 12
            font.letterSpacing: 2
        }

        // Main Panel
        Row {
            anchors.centerIn: parent
            spacing: 50

            // Speed and RPM Section
            Column {
                spacing: 10
                Text {
                    text: carTelemetry.speed.toFixed(1)
                    font.pixelSize: 120
                    color: "#00ff99"
                    font.bold: true
                    anchors.horizontalCenter: parent
                }
                Text {
                    text: "KM/H"
                    font.pixelSize: 24
                    color: "#333"
                    font.letterSpacing: 4
                    anchors.horizontalCenter: parent
                }
                
                // RPM Bar (Horizontal)
                Rectangle {
                    width: 250; height: 10; color: "#1a1a1a"; radius: 5
                    Rectangle {
                        width: (carTelemetry.rpm / 8000) * parent.width
                        height: parent.height; color: "#00ff99"; radius: 5
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }
                }
                Text {
                    text: carTelemetry.rpm + " RPM"
                    color: "#00ff99"
                    font.pixelSize: 16
                    anchors.horizontalCenter: parent
                }
            }

            // Indicator Group
            Row {
                spacing: 30
                
                VerticalBar {
                    label: "VOLTS"
                    value: carTelemetry.batteryVoltage
                    maxValue: 16.8
                    unit: "V"
                    barColor: carTelemetry.batteryVoltage < 11.5 ? "#ff3333" : "#0088ff"
                }

                VerticalBar {
                    label: "MOTOR"
                    value: carTelemetry.motorTemperature
                    maxValue: 100
                    unit: "°C"
                    barColor: carTelemetry.motorTemperature > 75 ? "#ff6600" : "#ffffff"
                }

                VerticalBar {
                    label: "OIL"
                    value: carTelemetry.oilTemperature
                    maxValue: 120
                    unit: "°C"
                    barColor: carTelemetry.oilTemperature > 95 ? "#ff3333" : "#ffcc00"
                }
            }
        }
    }
}
