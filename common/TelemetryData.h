#ifndef TELEMETRY_DATA_H
#define TELEMETRY_DATA_H

#include <cstdint>

/**
 * @brief TelemetryPacket structure defines the binary layout of incoming telemetry data.
 * 
 * Used for receiving real-time MCU state via UDP. Memory alignment is packed
 * to 1 byte to ensure cross-platform compatibility and avoid padding issues.
 */
#pragma pack(push, 1)
struct TelemetryPacket {
    /// @brief CPU usage as a percentage (0-100).
    uint8_t  cpu_usage_percent; 
    
    /// @brief Available RAM space in bytes.
    uint32_t free_heap_bytes;   
    
    /// @brief Time in seconds since the MCU started.
    uint32_t uptime_seconds;    
    
    /// @brief Temperature of the MCU core in Celsius.
    int16_t  mcu_temp_c;        
    
    /// @brief Null-terminated log message. Max 47 characters + null terminator.
    char     log_message[48];   
};
#pragma pack(pop)

#endif // TELEMETRY_DATA_H
