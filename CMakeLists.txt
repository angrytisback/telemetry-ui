cmake_minimum_required(VERSION 3.16)
project(TelemetriUI VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Gui Qml Quick Network)

# Main Executable
qt_add_executable(telemetri_ui
    main_ui.cpp
    common/TelemetryBridge.cpp
    common/TelemetryBridge.h
    common/TelemetryData.h
    TelemetryReceiver.cpp
    TelemetryReceiver.h
    qml.qrc
    telemetry.qrc
)

target_include_directories(telemetri_ui PRIVATE common)

target_link_libraries(telemetri_ui PRIVATE 
    Qt6::Gui 
    Qt6::Qml 
    Qt6::Quick 
    Qt6::Network
)

# For testing
enable_testing()
add_subdirectory(tests)

