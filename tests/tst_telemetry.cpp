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
        packet.avionics_temp = 68.5f;
        packet.bus_voltage = 48.2f;
        packet.vehicle_speed = 30.5f;
        packet.defense_readiness = 94;
        packet.target_x = 0.45f;
        packet.target_y = -0.32f;
        packet.tactical_event = 1;
        
        QSignalSpy tempSpy(&receiver, &TelemetryReceiver::avionicsTempChanged);
        QSignalSpy voltSpy(&receiver, &TelemetryReceiver::busVoltageChanged);
        QSignalSpy speedSpy(&receiver, &TelemetryReceiver::vehicleSpeedChanged);
        QSignalSpy targetSpy(&receiver, &TelemetryReceiver::tacticalTargetChanged);
        QSignalSpy eventSpy(&receiver, &TelemetryReceiver::tacticalEventReceived);
        
        QByteArray data(reinterpret_cast<const char*>(&packet), sizeof(packet));
        senderSocket.writeDatagram(data, QHostAddress::LocalHost, 5555);
        
        // Process events to allow UDP delivery
        QVERIFY(tempSpy.wait(1000));
        QCOMPARE(tempSpy.count(), 1);
        QCOMPARE(tempSpy.takeFirst().at(0).toFloat(), 68.5f);
        
        QCOMPARE(voltSpy.count(), 1);
        QCOMPARE(voltSpy.takeFirst().at(0).toFloat(), 48.2f);

        QCOMPARE(speedSpy.count(), 1);
        QCOMPARE(speedSpy.takeFirst().at(0).toFloat(), 30.5f);

        QCOMPARE(targetSpy.count(), 1);
        QList<QVariant> targetArgs = targetSpy.takeFirst();
        QCOMPARE(targetArgs.at(0).toFloat(), 0.45f);
        QCOMPARE(targetArgs.at(1).toFloat(), -0.32f);
        
        QCOMPARE(eventSpy.count(), 1);
        QList<QVariant> eventArgs = eventSpy.takeFirst();
        QCOMPARE(eventArgs.at(0).toInt(), 1);
        QCOMPARE(eventArgs.at(2).toString(), QString("INFO"));
    }
};

QTEST_MAIN(TestTelemetry)
#include "tst_telemetry.moc"
