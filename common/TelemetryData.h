#ifndef TELEMETRY_DATA_H
#define TELEMETRY_DATA_H

#include <cstdint>

/**
 * @brief TelemetryPacket defines the binary layout for Alaz Team Air Defense (Çelik Kubbe)
 *        and Unmanned Ground Vehicle (İKA) telemetry.
 *
 * Byte order: Little-Endian (<fffBffB)
 * Total Size: 22 Bytes (1-byte packed, no compiler padding)
 */
#if defined(__GNUC__) || defined(__clang__)
#define ALAZ_PACKED __attribute__((packed))
#else
#define ALAZ_PACKED
#endif

#pragma pack(push, 1)
struct ALAZ_PACKED TelemetryPacket {
    /// @brief Aviyonik / Radar işlemci sıcaklığı (°C, float32, 4 bytes)
    float avionics_temp;

    /// @brief İKA / Hava Savunma Güç Barası Gerilimi (V, float32, 4 bytes)
    float bus_voltage;

    /// @brief İKA Araç İlerleme Hızı (km/s, float32, 4 bytes)
    float vehicle_speed;

    /// @brief Hava Savunma & Sistem Hazırlık Oranı (% 0-100, uint8, 1 byte)
    uint8_t defense_readiness;

    /// @brief Taktik Hedef / Tehdit Azimut X (-1.0 ile +1.0 normalize, float32, 4 bytes)
    float target_x;

    /// @brief Taktik Hedef / Tehdit Menzil Y (-1.0 ile +1.0 normalize, float32, 4 bytes)
    float target_y;

    /// @brief Çelik Kubbe / İKA Taktik Olay ve Durum Kodu (uint8, 1 byte)
    uint8_t tactical_event;
};
#pragma pack(pop)

#undef ALAZ_PACKED

static_assert(sizeof(TelemetryPacket) == 22, "TelemetryPacket must be exactly 22 bytes packed");

#endif // TELEMETRY_DATA_H
