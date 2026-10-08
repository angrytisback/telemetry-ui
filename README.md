# Alaz Takımı - Çelik Kubbe Hava Savunma & İKA Komuta Kontrol İstasyonu

**Alaz SCADA Telemetri Sistemi**, Qt6 / QML ve C++17 mimarisi üzerine inşa edilmiş; insansız kara araçları (İKA) ve Çelik Kubbe hava savunma entegrasyonu için geliştirilmiş profesyonel bir komuta kontrol ve yer istasyonu arayüzüdür.

Sistem, harici donanım veya Python simülatörü üzerinden UDP protokolü (port 4444) ile gelen taktik telemetri verilerini gerçek zamanlı (10 Hz+) olarak işler, görselleştirir ve analiz eder.

---

## 🚀 Ekran Düzeni ve Taktik Telemetri Alanları

Arayüz, **Alaz Takımı** kurumsal kimliğine uygun derin uzay siyahı (`#09090b`), katı paneller (`#121217`, `#171720`) ve pastel tonlu mühendislik göstergeleri ile 3 ana kolonda tasarlanmıştır:

### 1. Üst Bar (Header Bar)
- **Kurumsal Kimlik**: Alaz Takımı vektörel SVG logosu ve `ÇELİK KUBBE` rozeti.
- **Taktik Durum**: `UDP: 127.0.0.1:4444`, `UPTIME` sayacı ve dijital sistem saati.

### 2. Sol Kolon: İKA & Güç Sistemi Telemetrisi
- **Aviyonik / İşlemci Sıcaklığı (Avionics Temp)**: `QtQuick.Shapes` yarım daire (Arc) göstergesi (0 - 120 °C).
- **Batarya Güç Barası Gerilimi (Bus Voltage)**: İKA ana batarya voltaj kadranı (0 - 60 V, 48V LiFePO4 sistemi).
- **İKA İlerleme Hızı (Vehicle Speed)**: İKA arazi ilerleme hızı yatay bar göstergesi (0 - 50 km/s).

### 3. Orta Kolon: Çelik Kubbe Hava Savunma Radarı & Zaman Grafiği
- **Çelik Kubbe Entegre Hava Savunma Radarı**:
  - Katmanlı savunma menzilleri: İç Hat / Yakın Savunma (2 km), Kısa Menzil İKA (5 km), Orta Menzil (10 km), Erken İhbar (15 km).
  - Taktik hedef telemetrisi: Otomatik hesaplanan Azimut açısı (`000° - 359°`), hedef menzili (`km`) ve hedef reticle'ı (`[İHA-T1]`).
- **Gerçek Zamanlı Taktik Telemetri Grafiği (QtCharts LineSeries)**:
  - Aviyonik Sıcaklığı (°C) ve Batarya Bara Voltajı (V) dinamik kayan çizgi grafiği.

### 4. Sağ Kolon: Taktik Olay Günlüğü ve Hazırlık Seviyesi
- **Çelik Kubbe & İKA Taktik Günlük (ListView)**:
  - Seviyeler: `[CRIT]`, `[WARN]`, `[INFO]`.
  - Tehdit tespitleri, IFF (Dost/Düşman) kontrolleri ve İKA devriye durumları.
- **Hava Savunma Hazırlık Oranı (Defense Readiness Doughnut)**:
  - %0 - %100 arası mühimmat ve sistem operasyonel teyakkuz halka göstergesi.

---

## 📡 UDP Telemetri Protokolü (22 Bayt Packed)

Veriler dış dünyadan (İKA otopilotu veya Python simülatörü) Little-Endian formatında, 1 bayt hizalamalı (packed) olarak iletilir:

| Alan Adı | Tip | Boyut | Açıklama |
| :--- | :--- | :--- | :--- |
| `avionics_temp` | `float32` | 4 Bayt | Aviyonik / Radar işlemci sıcaklığı (°C) |
| `bus_voltage` | `float32` | 4 Bayt | İKA / Sistem batarya güç barası gerilimi (V) |
| `vehicle_speed` | `float32` | 4 Bayt | İKA arazi ilerleme hızı (km/s) |
| `defense_readiness` | `uint8_t` | 1 Bayt | Savunma ve mühimmat hazırlık seviyesi (% 0-100) |
| `target_x` | `float32` | 4 Bayt | Radar hedef azimut X ekseni (-1.0 ile +1.0) |
| `target_y` | `float32` | 4 Bayt | Radar hedef menzil Y ekseni (-1.0 ile +1.0) |
| `tactical_event` | `uint8_t` | 1 Bayt | Taktik durum / olay kodu (0 - 5) |

**Toplam Boyut:** `22 Bayt` (`#pragma pack(push, 1)`)

---

## 🛠️ Kurulum ve Çalıştırma

### Derleme
```bash
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### Testleri Çalıştırma
```bash
cd build
ctest -V
```

### Simülatörü ve SCADA'yı Çalıştırma

1. **Terminal 1 - Taktik Mock Veri Gönderici:**
```bash
python3 mock_sender.py
```

2. **Terminal 2 - SCADA Yer İstasyonu:**
```bash
./build/telemetri_ui
```

---

## 🪟 Windows (Cross-Platform & Dağıtım)

Proje hem Linux hem de Windows için tam uyumludur:
- **Tek Tıkla Windows Derleme & Dağıtım:** `build_windows.bat` veya `build_windows.ps1`
- **Linux (Arch/CachyOS) Üzerinden Cross-Compile:** `x86_64-w64-mingw32-cmake`
- **Ayrıntılı Kılavuz:** [docs/WINDOWS_BUILD.md](docs/WINDOWS_BUILD.md) dosyasını inceleyin.
