import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Shapes

Window {
    id: root
    width: 1024
    height: 600
    visible: true
    title: "MCU Profiler Dashboard"
    color: "#080f1e" // Industrial slate theme

    // Backend values
    property int cpu: 0
    property int heap: 0
    property int uptime: 0
    property int temp: 0

    // Animated values for smooth transitions
    property real displayCpu: 0
    Behavior on displayCpu { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    property real displayHeap: 0
    Behavior on displayHeap { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    property real displayTemp: 0
    Behavior on displayTemp { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    Connections {
        target: telemetry
        
        function onCpuUsageChanged(val) { cpu = val; displayCpu = val; }
        function onHeapChanged(val) { heap = val; displayHeap = val; }
        function onUptimeChanged(val) { uptime = val; }
        function onTempChanged(val) { temp = val; displayTemp = val; }
        
        function onLogMessageReceived(msg) { 
            let timeStr = new Date().toLocaleTimeString(Qt.locale(), "hh:mm:ss");
            logModel.append({ "logText": "[" + timeStr + "] " + msg });
            if (logModel.count > 100) {
                logModel.remove(0); // Keep only the latest 100 messages
            }
            logListView.positionViewAtEnd();
        }
    }

    // Function to determine CPU color based on load
    function getCpuColor(val) {
        if (val < 50) return "#10b981" // Green (Normal)
        if (val < 85) return "#f59e0b" // Yellow (Warning)
        return "#ef4444" // Red (Critical)
    }

    // Helper: Format bytes to KB
    function formatHeap(bytes) {
        return (bytes / 1024.0).toFixed(1) + " KB";
    }

    function formatUptime(seconds) {
        let h = Math.floor(seconds / 3600);
        let m = Math.floor((seconds % 3600) / 60);
        let s = seconds % 60;
        return (h > 0 ? h + "h " : "") + (m > 0 ? m + "m " : "") + s + "s";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        // TOP SECTION: Panels and Gauge
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 30

            // LEFT PANEL: Free RAM and Uptime
            ColumnLayout {
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                spacing: 20
                
                Item { Layout.fillHeight: true } // Vertical centering

                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    color: "#111827"
                    radius: 12
                    border.color: "#1f2937"
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: "FREE RAM"
                            color: "#9ca3af"
                            font.pixelSize: 16
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: formatHeap(displayHeap)
                            color: displayHeap < 20480 ? "#ef4444" : "#3b82f6" // Red if below 20KB
                            font.pixelSize: 32
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    color: "#111827"
                    radius: 12
                    border.color: "#1f2937"
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: "UPTIME"
                            color: "#9ca3af"
                            font.pixelSize: 16
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: formatUptime(uptime)
                            color: "#10b981"
                            font.pixelSize: 32
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                Item { Layout.fillHeight: true } // Vertical centering
            }

            // CENTER: CPU Load
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 300

                Shape {
                    id: gaugeShape
                    anchors.fill: parent
                    layer.enabled: true
                    layer.samples: 4

                    property real centerX: width / 2
                    property real centerY: height / 2
                    property real arcRadius: Math.min(width, height) / 2.2

                    ShapePath {
                        strokeWidth: 25
                        strokeColor: "#1e293b"
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: gaugeShape.centerX; centerY: gaugeShape.centerY
                            radiusX: gaugeShape.arcRadius; radiusY: gaugeShape.arcRadius
                            startAngle: 135; sweepAngle: 270
                        }
                    }

                    ShapePath {
                        strokeWidth: 25
                        strokeColor: getCpuColor(displayCpu)
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: gaugeShape.centerX; centerY: gaugeShape.centerY
                            radiusX: gaugeShape.arcRadius; radiusY: gaugeShape.arcRadius
                            startAngle: 135
                            sweepAngle: Math.min((displayCpu / 100.0) * 270.0, 270.0)
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: -10
                    Text {
                        text: "%" + Math.round(displayCpu)
                        color: "white"
                        font.pixelSize: 90
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "CPU LOAD"
                        color: "#9ca3af"
                        font.pixelSize: 18
                        font.bold: true
                        font.letterSpacing: 2
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // RIGHT PANEL: Core Temperature
            ColumnLayout {
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                spacing: 20
                
                Item { Layout.fillHeight: true } 

                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    color: "#111827"
                    radius: 12
                    border.color: "#1f2937"
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: "CORE TEMP"
                            color: "#9ca3af"
                            font.pixelSize: 16
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: Math.round(displayTemp) + " °C"
                            color: displayTemp >= 75 ? "#ef4444" : "#f59e0b"
                            font.pixelSize: 36
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                Item { Layout.fillHeight: true } 
            }
        }

        // BOTTOM SECTION: Terminal (Profiler Log)
        Rectangle {
            Layout.fillWidth: true
            height: 160
            color: "#000000" // Solid black background
            border.color: "#334155"
            border.width: 2
            radius: 8
            clip: true

            ListModel {
                id: logModel
            }

            ListView {
                id: logListView
                anchors.fill: parent
                anchors.margins: 10
                model: logModel
                spacing: 4
                
                // Scroll animations
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 200 }
                }

                delegate: Text {
                    text: model.logText
                    color: "#34d399" // Terminal green
                    font.family: "Monospace"
                    font.pixelSize: 14
                    width: logListView.width
                    wrapMode: Text.Wrap
                }
            }
            
            // Terminal Header (Small text in corner)
            Text {
                text: "MCU CONSOLE"
                color: "#475569"
                font.pixelSize: 12
                font.bold: true
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
            }
        }
    }
}
