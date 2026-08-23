cmake_minimum_required(VERSION 3.16)
project(TelemetriUITests)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Test Network)

qt_add_executable(tst_telemetry
    tst_telemetry.cpp
    ../common/TelemetryBridge.cpp
    ../common/TelemetryBridge.h
    ../TelemetryReceiver.cpp
    ../TelemetryReceiver.h
)
target_include_directories(tst_telemetry PRIVATE ../common ../)
target_link_libraries(tst_telemetry PRIVATE Qt6::Test Qt6::Network)

add_test(NAME tst_telemetry COMMAND tst_telemetry)
