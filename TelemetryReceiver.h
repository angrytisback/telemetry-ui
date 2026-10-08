#ifndef TELEMETRYRECEIVER_H
#define TELEMETRYRECEIVER_H

#include <QObject>
#include <QUdpSocket>
#include <QString>
#include <QTimer>
#include "common/TelemetryData.h"

/**
 * @brief TelemetryReceiver manages high-speed UDP reception of Air Defense (Çelik Kubbe)
 *        and Unmanned Ground Vehicle (İKA) telemetry packets.
 */
class TelemetryReceiver : public QObject
{
    Q_OBJECT

public:
    explicit TelemetryReceiver(QObject *parent = nullptr);
    ~TelemetryReceiver() override;

    Q_INVOKABLE bool startListening(quint16 port = 4444);

signals:
    // Çelik Kubbe & İKA Taktik Sinyalleri
    void avionicsTempChanged(float temp);
    void busVoltageChanged(float voltage);
    void vehicleSpeedChanged(float speed);
    void defenseReadinessChanged(int percent);
    void tacticalTargetChanged(float x, float y);
    void tacticalEventReceived(int eventCode, const QString &description, const QString &level);
    void uptimeChanged(int uptimeSeconds);

    // Geriye dönük uyumluluk sinyalleri
    void coreTempChanged(float temp);
    void pressureChanged(float pressure);
    void flowRateChanged(float flowRate);
    void efficiencyChanged(int efficiency);
    void radarTargetChanged(float x, float y);
    void eventReceived(int eventCode, const QString &description, const QString &level);

private slots:
    void processPendingDatagrams();
    void onUptimeTick();

private:
    QUdpSocket *m_udpSocket{nullptr};
    QTimer *m_uptimeTimer{nullptr};
    int m_uptimeSeconds{0};
    uint8_t m_lastEventCode{255};
};

#endif // TELEMETRYRECEIVER_H
