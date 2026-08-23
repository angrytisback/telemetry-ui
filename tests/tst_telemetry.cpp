#include <QtTest>
#include <QSignalSpy>
#include <QNetworkDatagram>
#include "../common/TelemetryBridge.h"
#include "../TelemetryReceiver.h"
#include "../common/TelemetryData.h"

class TestTelemetry : public QObject
{
    Q_OBJECT

private slots:
    void testTelemetryBridgeSignals() {
        TelemetryBridge bridge;
        
        QSignalSpy voltageSpy(&bridge, &TelemetryBridge::batteryVoltageChanged);
        QSignalSpy motorTempSpy(&bridge, &TelemetryBridge::motorTemperatureChanged);
        
        bridge.setBatteryVoltage(12.5f);
        QCOMPARE(voltageSpy.count(), 1);
        QCOMPARE(bridge.batteryVoltage(), 12.5f);
        
        // Setting same value should NOT emit signal (qFuzzyCompare test)
        bridge.setBatteryVoltage(12.5f);
        QCOMPARE(voltageSpy.count(), 1);
        
        bridge.setMotorTemperature(85.0f);
        QCOMPARE(motorTempSpy.count(), 1);
        QCOMPARE(bridge.motorTemperature(), 85.0f);
    }

    void testTelemetryBridgeJsonLoad() {
        TelemetryBridge bridge;
        
        // Create a temporary JSON file
        QString jsonPath = "test_telemetry.json";
        QFile file(jsonPath);
        if (file.open(QIODevice::WriteOnly)) {
            file.write("{\"batteryVoltage\": 14.2, \"speed\": 105.5, \"rpm\": 3500}");
            file.close();
        }
        
        bridge.loadFromJson(jsonPath);
        
        QCOMPARE(bridge.batteryVoltage(), 14.2f);
        QCOMPARE(bridge.speed(), 105.5f);
        QCOMPARE(bridge.rpm(), 3500);
        
        // Cleanup
        QFile::remove(jsonPath);
    }
    
    void testTelemetryReceiverSockets() {
        TelemetryReceiver receiver;
        
        QVERIFY2(receiver.startListening(5555), "Should successfully bind to a test port");
        
        // Set up a sender socket
        QUdpSocket senderSocket;
        TelemetryPacket packet{};
        packet.cpu_usage_percent = 45;
        packet.free_heap_bytes = 10240;
        packet.uptime_seconds = 120;
        packet.mcu_temp_c = 42;
        strncpy(packet.log_message, "Test Message", sizeof(packet.log_message) - 1);
        
        QSignalSpy cpuSpy(&receiver, &TelemetryReceiver::cpuUsageChanged);
        QSignalSpy logSpy(&receiver, &TelemetryReceiver::logMessageReceived);
        
        QByteArray data(reinterpret_cast<const char*>(&packet), sizeof(packet));
        senderSocket.writeDatagram(data, QHostAddress::LocalHost, 5555);
        
        // Process events to allow UDP delivery
        QVERIFY(cpuSpy.wait(1000));
        QCOMPARE(cpuSpy.count(), 1);
        
        QList<QVariant> arguments = cpuSpy.takeFirst();
        QCOMPARE(arguments.at(0).toInt(), 45);
        
        QCOMPARE(logSpy.count(), 1);
        QCOMPARE(logSpy.first().at(0).toString(), QString("Test Message"));
    }
};

QTEST_MAIN(TestTelemetry)
#include "tst_telemetry.moc"
