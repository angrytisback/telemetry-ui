#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include "TelemetryReceiver.h"
#include "common/TelemetryBridge.h"

/**
 * @brief Main entry point for the TelemetriUI application.
 * 
 * Initializes the GUI application, QML engine, and sets up
 * the telemetry data connections before loading the UI.
 * 
 * @param argc Number of command-line arguments.
 * @param argv Array of command-line arguments.
 * @return Application exit code.
 */
int main(int argc, char *argv[]) {
    // Set up modern Qt configurations if needed
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);
    app.setOrganizationName("OpenSource");
    app.setOrganizationDomain("opensource.org");
    app.setApplicationName("TelemetriUI");

    QQmlApplicationEngine engine;
    
    // Create and initialize the UDP Telemetry Receiver
    TelemetryReceiver mcuTelemetry;
    if (!mcuTelemetry.startListening(4444)) {
        qWarning() << "Warning: Telemetry receiver could not bind to port 4444.";
    }
    
    // Create the vehicle Telemetry Bridge
    TelemetryBridge carTelemetry;
    
    // Try to load simulated data if available
    carTelemetry.loadFromJson(":/telemetry.json");
    
    // We expose both backend systems to QML explicitly
    engine.rootContext()->setContextProperty("telemetry", &mcuTelemetry);
    engine.rootContext()->setContextProperty("carTelemetry", &carTelemetry);
    
    // Fail-safe object creation validation
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url = QUrl(QStringLiteral("qrc:/Main.qml"))](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Fatal Error: Failed to load root QML file!";
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    
    // Load the main view
    engine.load(QUrl(QStringLiteral("qrc:/Main.qml")));

    return QGuiApplication::exec();
}
