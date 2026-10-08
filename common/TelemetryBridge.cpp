#include "TelemetryBridge.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>
#include <qmath.h>

TelemetryBridge::TelemetryBridge(QObject *parent) 
    : QObject(parent) 
{
}

float TelemetryBridge::batteryVoltage() const noexcept { return m_batteryVoltage; }
float TelemetryBridge::motorTemperature() const noexcept { return m_motorTemperature; }
float TelemetryBridge::speed() const noexcept { return m_speed; }
int TelemetryBridge::rpm() const noexcept { return m_rpm; }
float TelemetryBridge::oilTemperature() const noexcept { return m_oilTemperature; }

void TelemetryBridge::loadFromJson(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Failed to open telemetry JSON file:" << path;
        return;
    }

    QJsonParseError parseError{};
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    
    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "Failed to parse JSON:" << parseError.errorString();
        return;
    }

    if (!doc.isObject()) {
        qWarning() << "JSON is not an object.";
        return;
    }

    QJsonObject obj = doc.object();
            
    if (obj.contains("batteryVoltage")) setBatteryVoltage(static_cast<float>(obj["batteryVoltage"].toDouble()));
    if (obj.contains("motorTemperature")) setMotorTemperature(static_cast<float>(obj["motorTemperature"].toDouble()));
    if (obj.contains("speed")) setSpeed(static_cast<float>(obj["speed"].toDouble()));
    if (obj.contains("rpm")) setRpm(obj["rpm"].toInt());
    if (obj.contains("oilTemperature")) setOilTemperature(static_cast<float>(obj["oilTemperature"].toDouble()));
}

void TelemetryBridge::setBatteryVoltage(float v) {
    if (!qFuzzyCompare(1.0f + m_batteryVoltage, 1.0f + v)) {
        m_batteryVoltage = v;
        emit batteryVoltageChanged();
    }
}

void TelemetryBridge::setMotorTemperature(float t) {
    if (!qFuzzyCompare(1.0f + m_motorTemperature, 1.0f + t)) {
        m_motorTemperature = t;
        emit motorTemperatureChanged();
    }
}

void TelemetryBridge::setSpeed(float s) {
    if (!qFuzzyCompare(1.0f + m_speed, 1.0f + s)) {
        m_speed = s;
        emit speedChanged();
    }
}

void TelemetryBridge::setRpm(int r) {
    if (m_rpm != r) {
        m_rpm = r;
        emit rpmChanged();
    }
}

void TelemetryBridge::setOilTemperature(float t) {
    if (!qFuzzyCompare(1.0f + m_oilTemperature, 1.0f + t)) {
        m_oilTemperature = t;
        emit oilTemperatureChanged();
    }
}
