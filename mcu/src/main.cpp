#include <Arduino.h>
#include <TFT_eSPI.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include "../../common/TelemetryData.h"

// Wi-Fi Ayarları
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// UDP Ayarları
WiFiUDP udp;
const char* broadcastIP = "255.255.255.255";
const uint16_t udpPort = 4444;

// TFT objesi
TFT_eSPI tft = TFT_eSPI();

TelemetryPacket currentData;
unsigned long lastUpdate = 0;
const unsigned long UPDATE_INTERVAL = 250; // 250 ms güncelleme hızı (log mesajları da için)

// Terminal mesaj havuzu
const char* logMessages[] = {
    "Mem OK",
    "Task scheduled",
    "Allocating buffer...",
    "Network stable",
    "WiFi beacon received",
    "Interrupt triggered",
    "Watchdog fed",
    "Flash FS sync",
    "Stack check passed"
};

void setup() {
    Serial.begin(115200);
    
    tft.init();
    tft.setRotation(1); 
    tft.fillScreen(TFT_BLACK);
    
    // Wi-Fi Bağlantısı
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);
    tft.setTextColor(TFT_WHITE, TFT_BLACK);
    tft.drawString("WiFi Baglaniliyor...", 10, 10, 4);
    
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    
    tft.fillScreen(TFT_BLACK);
    tft.drawString("WiFi Baglandi!", 10, 10, 4);
    delay(1000);
    tft.fillScreen(TFT_BLACK);
    
    memset(&currentData, 0, sizeof(TelemetryPacket));
}

void generateMockData() {
    // Gerçek değerler
    currentData.free_heap_bytes = ESP.getFreeHeap();
    currentData.uptime_seconds = millis() / 1000;
    
    // CPU dalgalanması (0 - 100)
    static float mockCPU = 10.0;
    mockCPU += random(-15, 20);
    if (mockCPU < 0) mockCPU = 0;
    if (mockCPU > 100) mockCPU = 100;
    currentData.cpu_usage_percent = (uint8_t)mockCPU;
    
    // Çekirdek Sıcaklığı
    // (ESP32 dahili sıcaklığı temperatureRead() ile de alınabilir ancak dalgalansın diye mockluyoruz)
    currentData.mcu_temp_c = 45 + (currentData.cpu_usage_percent / 5) + random(-2, 3);

    // Bazen boş geçelim, bazen log mesajı gönderelim (UI tarafında sürekli satır atlamaması için %10 ihtimalle)
    memset(currentData.log_message, 0, sizeof(currentData.log_message)); 
    if (random(0, 100) > 85) {
        int rIndex = random(0, 9);
        strncpy(currentData.log_message, logMessages[rIndex], sizeof(currentData.log_message) - 1);
    }
}

void updateDisplay() {
    tft.setTextColor(TFT_WHITE, TFT_BLACK); 
    
    tft.drawString("CPU: " + String(currentData.cpu_usage_percent) + " %    ", 10, 10, 4);
    tft.drawString("RAM: " + String(currentData.free_heap_bytes) + " b  ", 10, 40, 4);
    tft.drawString("Uptime: " + String(currentData.uptime_seconds) + " s  ", 10, 70, 4);
    tft.drawString("Temp: " + String(currentData.mcu_temp_c) + " C  ", 10, 100, 4);
    
    if (currentData.log_message[0] != '\0') {
        tft.setTextColor(TFT_GREEN, TFT_BLACK);
        tft.drawString(String(currentData.log_message) + "               ", 10, 130, 2);
    }
}

void loop() {
    if (millis() - lastUpdate >= UPDATE_INTERVAL) {
        lastUpdate = millis();
        
        generateMockData();
        updateDisplay();
        
        udp.beginPacket(broadcastIP, udpPort);
        udp.write((const uint8_t*)&currentData, sizeof(TelemetryPacket));
        udp.endPacket();
    }
}
