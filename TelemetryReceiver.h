#ifndef TELEMETRYRECEIVER_H
#define TELEMETRYRECEIVER_H

#include <QObject>
#include <QUdpSocket>
#include <QString>
#include <memory>
#include "common/TelemetryData.h"

/**
 * @brief Class responsible for receiving telemetry UDP packets.
 * 
 * Listens on a specified port for TelemetryPacket data and emits
 * signals to notify the UI or other components of state changes.
 */
class TelemetryReceiver : public QObject
{
    Q_OBJECT
    
public:
    /**
     * @brief Constructs a TelemetryReceiver object.
     * @param parent The parent QObject (optional).
     */
    explicit TelemetryReceiver(QObject *parent = nullptr);
    
    /**
     * @brief Destroys the TelemetryReceiver, closing the socket.
     */
    ~TelemetryReceiver() override;

    /**
     * @brief Starts listening for incoming UDP datagrams on the specified port.
     * @param port The UDP port to bind to (default: 4444).
     * @return true if successfully bound, false otherwise.
     */
    Q_INVOKABLE bool startListening(quint16 port = 4444);

signals:
    /// @brief Emitted when CPU usage is updated.
    void cpuUsageChanged(int percent);
    
    /// @brief Emitted when available heap memory is updated.
    void heapChanged(unsigned int bytes);
    
    /// @brief Emitted when the uptime is updated.
    void uptimeChanged(unsigned int seconds);
    
    /// @brief Emitted when MCU temperature is updated.
    void tempChanged(int temperature);
    
    /// @brief Emitted when a new log message string is received.
    void logMessageReceived(const QString &message);

private slots:
    /// @brief Slot called when UDP datagrams are available to be read.
    void processPendingDatagrams();

private:
    std::unique_ptr<QUdpSocket> m_udpSocket;
};

#endif // TELEMETRYRECEIVER_H
