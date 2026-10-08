import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtCharts

ApplicationWindow {
    id: root
    width: 1366
    height: 820
    minimumWidth: 1100
    minimumHeight: 700
    visible: true
    title: "ALAZ - Çelik Kubbe Hava Savunma & İKA Komuta Kontrol"
    color: "#090708" // Ateş kırmızısı alt tonlu derin obsidyen

    // Genel Font (Windows: JetBrains Mono / Consolas, Linux: JetBrainsMono Nerd Font / monospace)
    readonly property string monoFont: "JetBrainsMono Nerd Font, JetBrains Mono, Consolas, monospace"
    font.family: monoFont

    // Çelik Kubbe & İKA Telemetri Değerleri
    property real avionicsTemp: 58.0      // Aviyonik / Radar işlemci sıcaklığı (°C)
    property real busVoltage: 48.5        // İKA 48V Batarya / Güç barası (V)
    property real vehicleSpeed: 24.0      // İKA Araç ilerleme hızı (km/s)
    property int defenseReadiness: 95     // Çelik Kubbe savunma hazırlık oranı (% 0-100)
    property int uptimeSeconds: 0
    property string currentTimeString: "00:00:00"

    // Dinamik Durum Renk Fonksiyonları (Normal: Yeşil -> Kötüleşirse: Sarı -> Turuncu -> Kırmızı)
    function getTempColor(val) {
        if (val < 62.0) return "#22c55e";      // Normal Sağlıklı (Yeşil)
        if (val < 72.0) return "#eab308";      // Isınma Başlangıcı (Sarı)
        if (val < 82.0) return "#f97316";      // Yüksek Sıcaklık (Turuncu)
        return "#e60000";                      // Kritik / Aşırı Sıcak (Ateş Kırmızısı)
    }

    function getVoltageColor(val) {
        if (val >= 47.5) return "#22c55e";     // Nominal / Dolu (Yeşil)
        if (val >= 44.5) return "#eab308";     // Azalan Voltaj (Sarı)
        if (val >= 43.0) return "#f97316";     // Düşük Batarya (Turuncu)
        return "#e60000";                      // Kritik Düşük Seviye (Ateş Kırmızısı)
    }

    function getSpeedColor(val) {
        if (val < 28.0) return "#22c55e";      // Güvenli Seyir (Yeşil)
        if (val < 38.0) return "#eab308";      // Hızlı (Sarı)
        if (val < 45.0) return "#f97316";      // Yüksek Hız (Turuncu)
        return "#e60000";                      // Limit Aşımı (Ateş Kırmızısı)
    }

    function getReadinessColor(val) {
        if (val >= 88) return "#22c55e";       // Tam Hazır (Yeşil)
        if (val >= 75) return "#eab308";       // Teyakkuz (Sarı)
        if (val >= 60) return "#f97316";       // Kısmi Hazır (Turuncu)
        return "#e60000";                      // Kritik Seviye (Ateş Kırmızısı)
    }

    // Animasyonlu Değerler (Sayısal geçişler)
    property real displayAvionicsTemp: avionicsTemp
    Behavior on displayAvionicsTemp { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

    property real displayBusVoltage: busVoltage
    Behavior on displayBusVoltage { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

    property real displayVehicleSpeed: vehicleSpeed
    Behavior on displayVehicleSpeed { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

    property real displayDefenseReadiness: defenseReadiness
    Behavior on displayDefenseReadiness { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

    // Dinamik Durum Renk Geçişleri (ColorAnimation ile yumuşak, kademeli geçiş)
    property color targetTempColor: getTempColor(displayAvionicsTemp)
    property color tempColor: targetTempColor
    Behavior on tempColor {
        ColorAnimation { duration: 600; easing.type: Easing.InOutQuad }
    }

    property color targetVoltageColor: getVoltageColor(displayBusVoltage)
    property color voltageColor: targetVoltageColor
    Behavior on voltageColor {
        ColorAnimation { duration: 600; easing.type: Easing.InOutQuad }
    }

    property color targetSpeedColor: getSpeedColor(displayVehicleSpeed)
    property color speedColor: targetSpeedColor
    Behavior on speedColor {
        ColorAnimation { duration: 600; easing.type: Easing.InOutQuad }
    }

    property color targetReadinessColor: getReadinessColor(displayDefenseReadiness)
    property color readinessColor: targetReadinessColor
    Behavior on readinessColor {
        ColorAnimation { duration: 600; easing.type: Easing.InOutQuad }
    }

    property int sampleCounter: 0

    // Saat Sayacı
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            currentTimeString = new Date().toLocaleTimeString(Qt.locale(), "hh:mm:ss");
        }
    }

    function formatUptime(totalSecs) {
        let h = Math.floor(totalSecs / 3600);
        let m = Math.floor((totalSecs % 3600) / 60);
        let s = totalSecs % 60;
        let pad = function(n) { return (n < 10 ? "0" : "") + n; }
        return pad(h) + ":" + pad(m) + ":" + pad(s);
    }

    // Backend Sinyal Bağlantıları
    Connections {
        target: telemetry

        function onAvionicsTempChanged(temp) {
            root.avionicsTemp = temp;
            pushChartData(temp, root.busVoltage);
        }

        function onBusVoltageChanged(volt) {
            root.busVoltage = volt;
        }

        function onVehicleSpeedChanged(speed) {
            root.vehicleSpeed = speed;
        }

        function onDefenseReadinessChanged(rate) {
            root.defenseReadiness = rate;
        }

        function onTacticalEventReceived(eventCode, description, level) {
            let timeStr = new Date().toLocaleTimeString(Qt.locale(), "hh:mm:ss");
            eventLogModel.insert(0, {
                "timestamp": timeStr,
                "code": eventCode,
                "description": description,
                "level": level
            });
            if (eventLogModel.count > 80) {
                eventLogModel.remove(eventLogModel.count - 1);
            }
        }

        function onUptimeChanged(uptime) {
            root.uptimeSeconds = uptime;
        }
    }

    // Grafik Veri Kaydırma
    function pushChartData(temp, volt) {
        sampleCounter++;
        tempSeries.append(sampleCounter, temp);
        voltageSeries.append(sampleCounter, volt * 2.0); // 48V -> ~96 grafik ekseninde

        if (tempSeries.count > 35) {
            tempSeries.remove(0);
            voltageSeries.remove(0);
            chartXAxis.min = tempSeries.at(0).x;
            chartXAxis.max = tempSeries.at(tempSeries.count - 1).x;
        } else {
            chartXAxis.min = 0;
            chartXAxis.max = Math.max(25, sampleCounter);
        }
    }

    // ==========================================
    // ANA ARAYÜZ YERLEŞİMİ (ATEŞ KIRMIZISI ALAZ SCADA)
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ----------------------------------------------------
        // ÜST BAR: Ateş Kırmızısı Vurgulu Taktik SCADA Başlığı
        // ----------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: "#130e10" // Koyu ateş kırmızısı paneli
            border.color: "#4a151b" // Ateş kırmızısı sınır
            border.width: 1
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // Sol: Alaz Logosu ve Başlık
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 12

                    Image {
                        source: "qrc:/alaz.svg"
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: 70
                        Layout.maximumHeight: 28
                        Layout.maximumWidth: 75
                        Layout.alignment: Qt.AlignVCenter
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    Rectangle {
                        width: 1
                        height: 20
                        color: "#4a151b"
                    }

                    Rectangle {
                        height: 22
                        width: 95
                        radius: 3
                        color: "#2b0a0e"
                        border.color: "#e60000" // Alaz Ateş Kırmızısı
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Çelik Kubbe"
                            color: "#ff2626"
                            font.pixelSize: 10
                            font.bold: true
                            font.family: root.monoFont
                        }
                    }

                    Text {
                        text: "Hava Savunma & İKA Komuta Kontrol Yer İstasyonu"
                        color: "#f8fafc"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.5
                        font.family: root.monoFont
                    }
                }

                Item { Layout.fillWidth: true }

                // Sağ: Soket, Uptime ve Saat
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8

                    Rectangle {
                        height: 28
                        width: 155
                        radius: 3
                        color: "#1c1114"
                        border.color: "#4a151b"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "UDP: 127.0.0.1:4444"
                            color: "#f8fafc"
                            font.pixelSize: 11
                            font.family: root.monoFont
                        }
                    }

                    Rectangle {
                        height: 28
                        width: 130
                        radius: 3
                        color: "#1c1114"
                        border.color: "#4a151b"
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "Uptime:"
                                color: "#94a3b8"
                                font.pixelSize: 10
                                font.bold: true
                                font.family: root.monoFont
                            }
                            Text {
                                text: formatUptime(root.uptimeSeconds)
                                color: "#ff4d4d"
                                font.pixelSize: 11
                                font.bold: true
                                font.family: root.monoFont
                            }
                        }
                    }

                    Rectangle {
                        height: 28
                        width: 85
                        radius: 3
                        color: "#1c1114"
                        border.color: "#4a151b"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.currentTimeString
                            color: "#f8fafc"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: root.monoFont
                        }
                    }
                }
            }
        }

        // ----------------------------------------------------
        // 3 KOLONLU GÖVDE YERLEŞİMİ
        // ----------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // ================================================
            // SOL KOLON: İKA & SİSTEM TELEMETRİSİ
            // ================================================
            Rectangle {
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                color: "#130e10"
                border.color: "#4a151b"
                border.width: 1
                radius: 4

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "İKA & Güç Sistem Telemetrisi"
                            color: "#ff2626" // Ateş kırmızısı başlık
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 0.5
                            font.family: root.monoFont
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 44
                            height: 16
                            radius: 2
                            color: "#2b0a0e"
                            border.color: "#e60000"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "Canlı"
                                color: "#ff4d4d"
                                font.pixelSize: 8
                                font.bold: true
                                font.family: root.monoFont
                            }
                        }
                    }

                    // 1. Kart: Aviyonik / İşlemci Sıcaklığı
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#181114"
                        border.color: "#3d1318"
                        border.width: 1
                        radius: 4

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Aviyonik Sıcaklığı"
                                    color: "#94a3b8"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.family: root.monoFont
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "0 - 120 °C"
                                    color: "#64748b"
                                    font.pixelSize: 9
                                    font.family: root.monoFont
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 90

                                Shape {
                                    id: tempShape
                                    anchors.fill: parent

                                    property real cx: width / 2
                                    property real cy: height * 0.75
                                    property real r: Math.min(width / 2.2, height * 0.70)

                                    ShapePath {
                                        strokeWidth: 12
                                        strokeColor: "#28171b"
                                        fillColor: "transparent"
                                        capStyle: ShapePath.FlatCap
                                        PathAngleArc {
                                            centerX: tempShape.cx; centerY: tempShape.cy
                                            radiusX: tempShape.r; radiusY: tempShape.r
                                            startAngle: 180; sweepAngle: 180
                                        }
                                    }

                                    // Dinamik Durum Rengi (Yumuşak Geçişli Animasyon)
                                    ShapePath {
                                        strokeWidth: 12
                                        strokeColor: root.tempColor
                                        fillColor: "transparent"
                                        capStyle: ShapePath.FlatCap
                                        PathAngleArc {
                                            centerX: tempShape.cx; centerY: tempShape.cy
                                            radiusX: tempShape.r; radiusY: tempShape.r
                                            startAngle: 180
                                            sweepAngle: Math.min(180, Math.max(0, (root.displayAvionicsTemp / 120.0) * 180))
                                        }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                    text: root.displayAvionicsTemp.toFixed(1) + " °C"
                                    color: root.tempColor
                                    font.pixelSize: 22
                                    font.bold: true
                                    font.family: root.monoFont
                                }
                            }
                        }
                    }

                    // 2. Kart: İKA Ana Güç Barası (Batarya Gerilimi)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#181114"
                        border.color: "#3d1318"
                        border.width: 1
                        radius: 4

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Batarya Güç Barası"
                                    color: "#94a3b8"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.family: root.monoFont
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "Nominal: 48V"
                                    color: "#64748b"
                                    font.pixelSize: 9
                                    font.family: root.monoFont
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 90

                                Shape {
                                    id: pressShape
                                    anchors.fill: parent

                                    property real cx: width / 2
                                    property real cy: height * 0.75
                                    property real r: Math.min(width / 2.2, height * 0.70)

                                    ShapePath {
                                        strokeWidth: 12
                                        strokeColor: "#28171b"
                                        fillColor: "transparent"
                                        capStyle: ShapePath.FlatCap
                                        PathAngleArc {
                                            centerX: pressShape.cx; centerY: pressShape.cy
                                            radiusX: pressShape.r; radiusY: pressShape.r
                                            startAngle: 160; sweepAngle: 220
                                        }
                                    }

                                    // Dinamik Durum Rengi (Yumuşak Geçişli Animasyon)
                                    ShapePath {
                                        strokeWidth: 12
                                        strokeColor: root.voltageColor
                                        fillColor: "transparent"
                                        capStyle: ShapePath.FlatCap
                                        PathAngleArc {
                                            centerX: pressShape.cx; centerY: pressShape.cy
                                            radiusX: pressShape.r; radiusY: pressShape.r
                                            startAngle: 160
                                            sweepAngle: Math.min(220, Math.max(0, (root.displayBusVoltage / 60.0) * 220))
                                        }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                    text: root.displayBusVoltage.toFixed(2) + " V"
                                    color: root.voltageColor
                                    font.pixelSize: 22
                                    font.bold: true
                                    font.family: root.monoFont
                                }
                            }
                        }
                    }

                    // 3. Kart: İKA İlerleme Hızı (Araç Hızı)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 95
                        color: "#181114"
                        border.color: "#3d1318"
                        border.width: 1
                        radius: 4

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "İKA İlerleme Hızı"
                                    color: "#94a3b8"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.family: root.monoFont
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: root.displayVehicleSpeed.toFixed(1) + " km/s"
                                    color: root.speedColor
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: root.monoFont
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 14
                                color: "#28171b"
                                radius: 2
                                clip: true

                                // Dinamik Durum Rengi Bar (Yumuşak Geçişli Animasyon)
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.min(parent.width, Math.max(0, (root.displayVehicleSpeed / 50.0) * parent.width))
                                    color: root.speedColor
                                    radius: 2
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "0 km/s"; color: "#64748b"; font.pixelSize: 9; font.family: root.monoFont }
                                Item { Layout.fillWidth: true }
                                Text { text: "25 km/s"; color: "#64748b"; font.pixelSize: 9; font.family: root.monoFont }
                                Item { Layout.fillWidth: true }
                                Text { text: "50 km/s (Maks)"; color: "#64748b"; font.pixelSize: 9; font.family: root.monoFont }
                            }
                        }
                    }
                }
            }

            // ================================================
            // ORTA KOLON: SİSTEM METRİKLERİ ALANI & TELEMETRİ GRAFİĞİ
            // ================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#130e10"
                border.color: "#4a151b"
                border.width: 1
                radius: 4

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // 1. Sistem Metrikleri (Boş / Entegrasyon Alanı)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 310
                        Layout.fillHeight: true
                        color: "#181114"
                        border.color: "#3d1318"
                        border.width: 1
                        radius: 4

                        RowLayout {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10

                            Text {
                                text: "Sistem Metrikleri"
                                color: "#ff2626"
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.5
                                font.family: root.monoFont
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "[ Entegrasyon Alanı ]"
                                color: "#64748b"
                                font.pixelSize: 9
                                font.family: root.monoFont
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            opacity: 0.45

                            Rectangle {
                                width: 44
                                height: 2
                                color: "#e60000"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Sistem Metrikleri Bekleniyor"
                                color: "#94a3b8"
                                font.pixelSize: 10
                                font.bold: true
                                font.family: root.monoFont
                                font.letterSpacing: 1.2
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // 2. Çizgi Grafik (QtCharts)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 310
                        Layout.fillHeight: true
                        color: "#181114"
                        border.color: "#3d1318"
                        border.width: 1
                        radius: 4

                        ChartView {
                            id: telemetryChart
                            anchors.fill: parent
                            anchors.margins: 4
                            antialiasing: true
                            backgroundColor: "transparent"
                            legend.alignment: Qt.AlignTop
                            legend.labelColor: "#f8fafc"
                            legend.font.pixelSize: 10
                            legend.font.bold: true
                            legend.font.family: root.monoFont

                            ValueAxis {
                                id: chartXAxis
                                min: 0
                                max: 35
                                labelsVisible: false
                                gridLineColor: "#271418"
                                lineVisible: true
                                color: "#4a151b"
                            }

                            ValueAxis {
                                id: chartYAxis
                                min: 0
                                max: 120
                                tickCount: 5
                                labelFormat: "%.0f"
                                labelsColor: "#94a3b8"
                                labelsFont.family: root.monoFont
                                labelsFont.pixelSize: 9
                                gridLineColor: "#271418"
                                lineVisible: true
                                color: "#4a151b"
                            }

                            // Sıcaklık Çizgisi: Alaz Ateş Kırmızısı
                            LineSeries {
                                id: tempSeries
                                name: "Aviyonik Sıcaklığı (°C)"
                                axisX: chartXAxis
                                axisY: chartYAxis
                                color: "#e60000" // Ateş Kırmızısı
                                width: 2.2
                            }

                            // Batarya Bara Gerilimi Çizgisi: Kontrast Sağlıklı Renk
                            LineSeries {
                                id: voltageSeries
                                name: "Batarya Gerilimi (x2 Ölçek / V)"
                                axisX: chartXAxis
                                axisY: chartYAxis
                                color: "#38bdf8" // Pastel Mavi
                                width: 2.2
                            }
                        }
                    }
                }
            }

            // ================================================
            // SAĞ KOLON: SAVUNMA OLAY GÜNLÜĞÜ VE HAZIRLIK ORANI
            // ================================================
            Rectangle {
                Layout.preferredWidth: 340
                Layout.fillHeight: true
                color: "#130e10"
                border.color: "#4a151b"
                border.width: 1
                radius: 4

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // 1. Taktik Olay Günlüğü
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#181114"
                        border.color: "#3d1318"
                        border.width: 1
                        radius: 4

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Çelik Kubbe & İKA Taktik Günlük"
                                    color: "#ff2626"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 0.5
                                    font.family: root.monoFont
                                }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 50
                                    height: 18
                                    radius: 2
                                    color: "#2b0a0e"
                                    border.color: "#e60000"
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: eventLogModel.count + " Kayıt"
                                        color: "#ff4d4d"
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.family: root.monoFont
                                    }
                                }
                            }

                            ListModel {
                                id: eventLogModel
                                ListElement {
                                    timestamp: "12:00:00"
                                    code: 0
                                    description: "Çelik Kubbe ağı senkronize. İKA hazır."
                                    level: "INFO"
                                }
                            }

                            ListView {
                                id: eventListView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 4
                                model: eventLogModel

                                delegate: Rectangle {
                                    width: eventListView.width
                                    height: 44
                                    radius: 2
                                    color: model.level === "CRIT" ? "#2a0c0e" : (model.level === "WARN" ? "#261c0c" : "#101e14")
                                    border.color: model.level === "CRIT" ? "#e60000" : (model.level === "WARN" ? "#eab308" : "#22c55e")
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 8

                                        Rectangle {
                                            width: 40
                                            height: 20
                                            radius: 2
                                            color: model.level === "CRIT" ? "#e60000" : (model.level === "WARN" ? "#eab308" : "#22c55e")

                                            Text {
                                                anchors.centerIn: parent
                                                text: model.level
                                                color: "#09090b"
                                                font.pixelSize: 9
                                                font.bold: true
                                                font.family: root.monoFont
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: model.description
                                                color: "#f8fafc"
                                                font.pixelSize: 10
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                font.family: root.monoFont
                                            }
                                            Text {
                                                text: model.timestamp + " [Sektör Kod:" + model.code + "]"
                                                color: "#94a3b8"
                                                font.pixelSize: 9
                                                font.family: root.monoFont
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 2. Hava Savunma Hazırlık Seviyesi
                    Rectangle {
                        Layout.fillWidth: true
                        height: 215
                        color: "#181114"
                        border.color: "#3d1318"
                        border.width: 1
                        radius: 4

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Savunma Hazırlık Oranı"
                                    color: "#94a3b8"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.family: root.monoFont
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: root.displayDefenseReadiness >= 88 ? "Tam Hazır" : (root.displayDefenseReadiness >= 75 ? "Teyakkuz" : "Mühimmat Kritik")
                                    color: root.readinessColor
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.family: root.monoFont
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Shape {
                                    id: doughnutShape
                                    anchors.centerIn: parent
                                    width: 130
                                    height: 130

                                    ShapePath {
                                        strokeWidth: 14
                                        strokeColor: "#28171b"
                                        fillColor: "transparent"
                                        capStyle: ShapePath.FlatCap
                                        PathAngleArc {
                                            centerX: 65; centerY: 65
                                            radiusX: 50; radiusY: 50
                                            startAngle: -90; sweepAngle: 360
                                        }
                                    }

                                    // Dinamik Durum Rengi (Yumuşak Geçişli Animasyon)
                                    ShapePath {
                                        strokeWidth: 14
                                        strokeColor: root.readinessColor
                                        fillColor: "transparent"
                                        capStyle: ShapePath.FlatCap
                                        PathAngleArc {
                                            centerX: 65; centerY: 65
                                            radiusX: 50; radiusY: 50
                                            startAngle: -90
                                            sweepAngle: (root.displayDefenseReadiness / 100.0) * 360
                                        }
                                    }
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: -2

                                    Text {
                                        text: "%" + Math.round(root.displayDefenseReadiness)
                                        color: root.readinessColor
                                        font.pixelSize: 26
                                        font.bold: true
                                        font.family: root.monoFont
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Text {
                                        text: "Hazırlık"
                                        color: "#94a3b8"
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.family: root.monoFont
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
