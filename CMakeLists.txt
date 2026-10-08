cmake_minimum_required(VERSION 3.16)
project(TelemetriUI VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Windows MSVC UTF-8 karakter kodlama desteği
if(MSVC)
    add_compile_options(/utf-8)
endif()

find_package(Qt6 REQUIRED COMPONENTS Gui Qml Quick Network Charts Widgets)

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

# Windows'ta arka planda boş CMD konsol penceresi açılmasını engelle
if(WIN32)
    set_target_properties(telemetri_ui PROPERTIES WIN32_EXECUTABLE TRUE)
endif()

target_include_directories(telemetri_ui PRIVATE common .)

target_link_libraries(telemetri_ui PRIVATE 
    Qt6::Gui 
    Qt6::Qml 
    Qt6::Quick 
    Qt6::Network
    Qt6::Charts
    Qt6::Widgets
)

# Windows platformunda Winsock2 kütüphanesini bağla (Statik ve MinGW derlemeleri için garanti)
if(WIN32)
    target_link_libraries(telemetri_ui PRIVATE ws2_32)
endif()

# Dağıtım / Kurulum hedefi
install(TARGETS telemetri_ui
    BUNDLE DESTINATION .
    RUNTIME DESTINATION .
    LIBRARY DESTINATION lib
)

# For testing
enable_testing()
add_subdirectory(tests)
