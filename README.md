# TelemetriUI

**TelemetriUI** is a modern, high-performance telemetry dashboard and bridge application built with Qt6/QML and C++17. Designed to interface seamlessly with embedded microcontrollers (MCUs) via UDP and support simulated static data parsing, it provides an industrial-grade, highly responsive user interface for monitoring metrics like CPU usage, RAM, Uptime, Temperature, Speed, RPM, and Battery Voltage.

## Features

- **Real-Time MCU Monitoring**: Connects to microcontrollers via UDP (default port 4444) with zero-cost data mapping from packed C-structs.
- **Dual Telemetry Domains**: 
  - `mcuTelemetry`: Dedicated for hardware metrics (CPU, RAM, Uptime).
  - `carTelemetry`: Dedicated for vehicle data (Speed, RPM, Voltage), mockable via JSON.
- **Hardware-Accelerated UI**: Qt Quick (QML) based UI offering 60+ FPS fluid animations.
- **Memory Safe & Idiomatic C++**: Enforces C++17 standards, RAII, smart pointers (`std::unique_ptr`), and `nodiscard` properties.
- **Comprehensive Test Suite**: QtTest framework integration covering data serialization, edge cases, and QSignal verifications.

## Architecture

The architecture enforces a strict separation of concerns between UI (QML) and Business Logic (C++):
- `TelemetryReceiver`: A robust UDP networking layer ensuring network packet alignment and memory-safe processing via `QNetworkDatagram`.
- `TelemetryBridge`: Acts as a data proxy for QML contexts and supports mocking state via `QJsonDocument`.
- `Dashboard.qml` & `Main.qml`: Declarative UI elements bound reactively to C++ signals ensuring minimal redraws.

## Prerequisites & Installation

### Requirements
- **CMake** >= 3.16
- **Qt 6.x** (Modules: Core, Gui, Qml, Quick, Network, Test)
- **C++17 Compatible Compiler** (GCC 9+, Clang 10+, MSVC 19.20+)

### Build Instructions

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/telemetriui.git
   cd telemetriui
   ```

2. **Configure with CMake:**
   ```bash
   cmake -B build -DCMAKE_BUILD_TYPE=Release
   ```

3. **Compile:**
   ```bash
   cmake --build build -j$(nproc)
   ```

4. **Run the Application:**
   ```bash
   ./build/telemetri_ui
   ```

## Testing

The repository ships with an exhaustive suite of unit and integration tests.

Run tests using CTest:
```bash
cd build
ctest --output-on-failure
```

Tests validate:
- Cross-platform struct padding guarantees (`TelemetryPacket`).
- Bound assertions on property setters using fuzzy comparison to prevent infinite loop QML re-evaluations.
- Integration tests ensuring correct QSignal propagation under rapid UDP packet ingestion.

## License

This project is open-source and available under the [MIT License](LICENSE).
