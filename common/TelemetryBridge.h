#ifndef TELEMETRY_BRIDGE_H
#define TELEMETRY_BRIDGE_H

#include <QObject>
#include <QString>

/**
 * @brief Bridge class for telemetry data between C++ and QML.
 * 
 * Provides an interface to set and get various telemetry properties
 * such as battery voltage, motor temperature, and speed. It also
 * supports loading a state from a JSON file.
 */
class TelemetryBridge : public QObject {
    Q_OBJECT
    Q_PROPERTY(float batteryVoltage READ batteryVoltage NOTIFY batteryVoltageChanged)
    Q_PROPERTY(float motorTemperature READ motorTemperature NOTIFY motorTemperatureChanged)
    Q_PROPERTY(float speed READ speed NOTIFY speedChanged)
    Q_PROPERTY(int rpm READ rpm NOTIFY rpmChanged)
    Q_PROPERTY(float oilTemperature READ oilTemperature NOTIFY oilTemperatureChanged)

public:
    /**
     * @brief Constructs a new TelemetryBridge object.
     * @param parent The parent QObject (optional).
     */
    explicit TelemetryBridge(QObject *parent = nullptr);

    /// @brief Gets the current battery voltage.
    /// @return Battery voltage as a float.
    [[nodiscard]] float batteryVoltage() const noexcept;

    /// @brief Gets the current motor temperature.
    /// @return Motor temperature in Celsius.
    [[nodiscard]] float motorTemperature() const noexcept;

    /// @brief Gets the current speed.
    /// @return Speed in km/h.
    [[nodiscard]] float speed() const noexcept;

    /// @brief Gets the current RPM.
    /// @return Engine/Motor RPM.
    [[nodiscard]] int rpm() const noexcept;

    /// @brief Gets the current oil temperature.
    /// @return Oil temperature in Celsius.
    [[nodiscard]] float oilTemperature() const noexcept;

    /**
     * @brief Loads telemetry data from a specified JSON file.
     * @param path The path to the JSON file.
     */
    Q_INVOKABLE void loadFromJson(const QString& path);

public slots:
    /// @brief Sets the battery voltage and emits changed signal if modified.
    void setBatteryVoltage(float v);

    /// @brief Sets the motor temperature and emits changed signal if modified.
    void setMotorTemperature(float t);

    /// @brief Sets the speed and emits changed signal if modified.
    void setSpeed(float s);

    /// @brief Sets the RPM and emits changed signal if modified.
    void setRpm(int r);

    /// @brief Sets the oil temperature and emits changed signal if modified.
    void setOilTemperature(float t);

signals:
    /// @brief Emitted when the battery voltage changes.
    void batteryVoltageChanged();
    
    /// @brief Emitted when the motor temperature changes.
    void motorTemperatureChanged();
    
    /// @brief Emitted when the speed changes.
    void speedChanged();
    
    /// @brief Emitted when the RPM changes.
    void rpmChanged();
    
    /// @brief Emitted when the oil temperature changes.
    void oilTemperatureChanged();

private:
    float m_batteryVoltage{0.0f};
    float m_motorTemperature{0.0f};
    float m_speed{0.0f};
    int m_rpm{0};
    float m_oilTemperature{0.0f};
};

#endif // TELEMETRY_BRIDGE_H
