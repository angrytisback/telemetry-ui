#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QFont>
#include <QFontInfo>
#include "TelemetryReceiver.h"
#include "common/TelemetryBridge.h"

/**
 * @brief Alaz Takımı SCADA / Komuta Kontrol Telemetri Arayüzü Ana Giriş Noktası.
 * 
 * QtCharts desteği için QApplication başlatır, QML motorunu ve UDP
 * telemetri alıcısını yapılandırır.
 */
int main(int argc, char *argv[]) {
    // QtCharts QML modülünün hatasız çalışması için QApplication gereklidir
    QApplication app(argc, argv);
    app.setOrganizationName("AlazTeam");
    app.setOrganizationDomain("alaztakimi.org");
    app.setApplicationName("Alaz SCADA Telemetri Sistemi");

    // Genel sistem yazı tipi: JetBrains Mono (Windows & Linux uyumlu geri çekilme ile)
    QFont appFont("JetBrainsMono Nerd Font");
    if (!QFontInfo(appFont).exactMatch()) {
        appFont.setFamily("JetBrains Mono");
        if (!QFontInfo(appFont).exactMatch()) {
#if defined(Q_OS_WIN)
            appFont.setFamily("Consolas");
#else
            appFont.setFamily("Monospace");
#endif
        }
    }
    appFont.setPointSize(10);
    appFont.setStyleHint(QFont::Monospace);
    app.setFont(appFont);

    QQmlApplicationEngine engine;
    
    // UDP Telemetri Alıcısını Başlat (Port: 4444)
    TelemetryReceiver mcuTelemetry;
    if (!mcuTelemetry.startListening(4444)) {
        qWarning() << "[HATA] Telemetri alıcısı 4444 portuna bağlanamadı!";
    }
    
    // Araç Telemetri Köprüsü (Statik / Simülasyon)
    TelemetryBridge carTelemetry;
    carTelemetry.loadFromJson(":/telemetry.json");
    
    // Backend nesnelerini QML context'ine aktar
    engine.rootContext()->setContextProperty("telemetry", &mcuTelemetry);
    engine.rootContext()->setContextProperty("carTelemetry", &carTelemetry);
    
    // Hata kontrolü
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url = QUrl(QStringLiteral("qrc:/Main.qml"))](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "[KRITIK HATA] Root QML (qrc:/Main.qml) yüklenemedi!";
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    
    // QML arayüzünü yükle
    engine.load(QUrl(QStringLiteral("qrc:/Main.qml")));

    return QApplication::exec();
}
