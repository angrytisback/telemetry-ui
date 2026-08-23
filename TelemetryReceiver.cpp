#include "TelemetryReceiver.h"
#include <QNetworkDatagram>
#include <QDebug>
#include <cstring> // For strnlen

TelemetryReceiver::TelemetryReceiver(QObject *parent)
    : QObject(parent),
      m_udpSocket(std::make_unique<QUdpSocket>(this))
{
    connect(m_udpSocket.get(), &QUdpSocket::readyRead, this, &TelemetryReceiver::processPendingDatagrams);
}

TelemetryReceiver::~TelemetryReceiver()
{
    m_udpSocket->close();
}

bool TelemetryReceiver::startListening(quint16 port)
{
    if (m_udpSocket->bind(QHostAddress::Any, port)) {
        qDebug() << "Listening for telemetry data on UDP port" << port;
        return true;
    }
    
    qWarning() << "Failed to bind to UDP port" << port;
    return false;
}

void TelemetryReceiver::processPendingDatagrams()
{
    while (m_udpSocket->hasPendingDatagrams()) {
        QNetworkDatagram datagram = m_udpSocket->receiveDatagram();
        QByteArray data = datagram.data();
        
        if (static_cast<size_t>(data.size()) == sizeof(TelemetryPacket)) {
            const auto* packet = reinterpret_cast<const TelemetryPacket*>(data.constData());
            
            emit cpuUsageChanged(packet->cpu_usage_percent);
            emit heapChanged(packet->free_heap_bytes);
            emit uptimeChanged(packet->uptime_seconds);
            emit tempChanged(packet->mcu_temp_c);
            
            // Only emit non-empty log messages
            if (packet->log_message[0] != '\0') {
                // Ensure string does not exceed the maximum size of 48 characters
                // Fallback to strnlen which is standard POSIX
                size_t len = strnlen(packet->log_message, sizeof(packet->log_message));
                QString logStr = QString::fromLocal8Bit(packet->log_message, static_cast<int>(len));
                emit logMessageReceived(logStr);
            }
        } else {
            qWarning() << "Invalid packet size received! Expected:" 
                       << sizeof(TelemetryPacket) << "Got:" << data.size();
        }
    }
}
