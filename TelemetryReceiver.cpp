#include "TelemetryReceiver.h"
#include <QNetworkDatagram>
#include <QDebug>
#include <QtEndian>
#include <cstring>

static float unpackLittleEndianFloat(float val)
{
    quint32 raw;
    std::memcpy(&raw, &val, sizeof(quint32));
    raw = qFromLittleEndian(raw);
    float result;
    std::memcpy(&result, &raw, sizeof(float));
    return result;
}

TelemetryReceiver::TelemetryReceiver(QObject *parent)
    : QObject(parent),
      m_udpSocket(new QUdpSocket(this)),
      m_uptimeTimer(new QTimer(this))
{
    connect(m_udpSocket, &QUdpSocket::readyRead, this, &TelemetryReceiver::processPendingDatagrams);

    connect(m_uptimeTimer, &QTimer::timeout, this, &TelemetryReceiver::onUptimeTick);
    m_uptimeTimer->start(1000);
}

TelemetryReceiver::~TelemetryReceiver()
{
    if (m_uptimeTimer) {
        m_uptimeTimer->stop();
    }
    if (m_udpSocket) {
        m_udpSocket->close();
    }
}

bool TelemetryReceiver::startListening(quint16 port)
{
    if (m_udpSocket->bind(QHostAddress::Any, port)) {
        qInfo() << "[TelemetryReceiver] Çelik Kubbe & İKA UDP Dinleme başladı -> Port:" << port;
        return true;
    }
    
    qWarning() << "[TelemetryReceiver] UDP Portuna bağlanılamadı -> Port:" << port;
    return false;
}

void TelemetryReceiver::onUptimeTick()
{
    m_uptimeSeconds++;
    emit uptimeChanged(m_uptimeSeconds);
}

void TelemetryReceiver::processPendingDatagrams()
{
    while (m_udpSocket->hasPendingDatagrams()) {
        QNetworkDatagram datagram = m_udpSocket->receiveDatagram();
        QByteArray data = datagram.data();
        
        if (static_cast<size_t>(data.size()) == sizeof(TelemetryPacket)) {
            TelemetryPacket packet;
            std::memcpy(&packet, data.constData(), sizeof(TelemetryPacket));
            
            float avionicsTemp = unpackLittleEndianFloat(packet.avionics_temp);
            float busVoltage = unpackLittleEndianFloat(packet.bus_voltage);
            float vehicleSpeed = unpackLittleEndianFloat(packet.vehicle_speed);
            int readiness = static_cast<int>(packet.defense_readiness);
            float targetX = unpackLittleEndianFloat(packet.target_x);
            float targetY = unpackLittleEndianFloat(packet.target_y);
            uint8_t eventCode = packet.tactical_event;

            // Hava Savunma & İKA Sinyalleri
            emit avionicsTempChanged(avionicsTemp);
            emit busVoltageChanged(busVoltage);
            emit vehicleSpeedChanged(vehicleSpeed);
            emit defenseReadinessChanged(readiness);
            emit tacticalTargetChanged(targetX, targetY);

            // Geriye dönük uyumluluk sinyalleri
            emit coreTempChanged(avionicsTemp);
            emit pressureChanged(busVoltage);
            emit flowRateChanged(vehicleSpeed);
            emit efficiencyChanged(readiness);
            emit radarTargetChanged(targetX, targetY);

            if (eventCode != m_lastEventCode) {
                m_lastEventCode = eventCode;
                QString level = "INFO";
                QString description;

                switch (eventCode) {
                    case 0:
                        level = "INFO";
                        description = "Çelik Kubbe ağı senkronize. İKA otonom devriye rotasında.";
                        break;
                    case 1:
                        level = "INFO";
                        description = "Hava Savunma Radarı: Hedef İHA tespit edildi. IFF sorgusu devrede.";
                        break;
                    case 2:
                        level = "WARN";
                        description = "Alçak irtifa mikro-İHA sürü tehdidi radar sektörüne girdi!";
                        break;
                    case 3:
                        level = "WARN";
                        description = "İKA güç tüketimi yüksek. Taret elektro-optik kilitlendi.";
                        break;
                    case 4:
                        level = "CRIT";
                        description = "ÇELİK KUBBE ALARMI: Tehdit hava savunma iç hattını (2km) ihlal etti!";
                        break;
                    case 5:
                        level = "INFO";
                        description = "Elektronik harp karıştırması bastırıldı. Lazer savunma hazır.";
                        break;
                    default:
                        level = (eventCode >= 10) ? "CRIT" : "WARN";
                        description = QString("Taktik durum/olay sinyali alındı (Kod: %1)").arg(eventCode);
                        break;
                }

                emit tacticalEventReceived(static_cast<int>(eventCode), description, level);
                emit eventReceived(static_cast<int>(eventCode), description, level);
            }
        } else {
            qWarning() << "[TelemetryReceiver] Hatalı paket boyutu! Beklenen:" 
                       << sizeof(TelemetryPacket) << "Alınan:" << data.size();
        }
    }
}
