#!/usr/bin/env python3
"""
Alaz Takımı - Çelik Kubbe & İKA Hava Savunma Telemetri Simülatörü (Mock Sender)
Bu script; Çelik Kubbe entegrasyonu, İnsansız Kara Aracı (İKA) sürüş telemetrisi
ve hava savunma radar verilerini 10 Hz frekansında UDP ile yayınlar.

Paket Yapısı (22 Bayt, Little-Endian, Packed: <fffBffB):
- avionics_temp (float32): Aviyonik / Radar işlemci sıcaklığı (°C)
- bus_voltage (float32): İKA Ana Güç Barası / Batarya Gerilimi (V - 48V Sistemi)
- vehicle_speed (float32): İKA Araç İlerleme Hızı (km/s)
- defense_readiness (uint8): Hava Savunma Hazırlık & Mühimmat Seviyesi (% 0-100)
- target_x (float32): Taktik Hedef / Tehdit Azimut X (-1.0 ile +1.0)
- target_y (float32): Taktik Hedef / Tehdit Menzil Y (-1.0 ile +1.0)
- tactical_event (uint8): Çelik Kubbe / İKA Olay Kodu (0-5)
"""

import socket
import struct
import time
import math
import random
import sys

UDP_IP = "127.0.0.1"
UDP_PORT = 4444
SEND_RATE_HZ = 10
INTERVAL = 1.0 / SEND_RATE_HZ

PACKET_FORMAT = "<fffBffB"
EXPECTED_SIZE = struct.calcsize(PACKET_FORMAT)

def main():
    print("=" * 70)
    print("  ALAZ TAKIMI - ÇELİK KUBBE & İKA TELEMETRİ SİMÜLATÖRÜ")
    print(f"  Hedef Port: {UDP_IP}:{UDP_PORT} (UDP)")
    print(f"  Paket Boyutu: {EXPECTED_SIZE} Bayt | Gönderim Frekansı: {SEND_RATE_HZ} Hz")
    print("=" * 70)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    step = 0
    last_event_time = time.time()
    current_event = 0

    try:
        while True:
            t = step * 0.1

            # 1. Aviyonik / Radar İşlemci Sıcaklığı (45°C - 78°C)
            temp_drift = math.sin(t * 0.12) * 12.0 + math.cos(t * 0.04) * 5.0
            avionics_temp = max(40.0, min(85.0, 58.0 + temp_drift + random.uniform(-0.3, 0.3)))

            # 2. İKA Güç Barası / Batarya Voltajı (47.0V - 53.5V nominal 48V)
            volt_drift = math.cos(t * 0.08) * 2.2 + math.sin(t * 0.2) * 0.5
            bus_voltage = max(42.0, min(56.0, 50.2 + volt_drift + random.uniform(-0.08, 0.08)))

            # 3. İKA İlerleme Hızı (0 - 45 km/s)
            speed_curve = max(0.0, math.sin(t * 0.18) * 32.0 + 8.0)
            vehicle_speed = max(0.0, min(50.0, speed_curve + random.uniform(-0.4, 0.4)))

            # 4. Hava Savunma & Sistem Hazırlık Seviyesi (88% - 100%)
            readiness_base = 96.0 - (max(0.0, avionics_temp - 70.0) * 0.3) + random.uniform(-0.5, 0.5)
            defense_readiness = int(max(70, min(100, round(readiness_base))))

            # 5. Radar Tehdit Koordinatları (Hedef İHA yaklaşma yörüngesi)
            angle = t * 0.35
            radius = 0.60 + 0.25 * math.sin(t * 0.15)
            target_x = float(radius * math.cos(angle) + random.uniform(-0.015, 0.015))
            target_y = float(radius * math.sin(angle) + random.uniform(-0.015, 0.015))
            target_x = max(-1.0, min(1.0, target_x))
            target_y = max(-1.0, min(1.0, target_y))

            # 6. Taktik Durum Olayları
            now = time.time()
            if now - last_event_time > 5.0:
                last_event_time = now
                if radius < 0.35:
                    current_event = 4  # Çelik Kubbe Alarmı: İç hat ihlali
                elif avionics_temp > 74.0:
                    current_event = 3  # Yüksek güç / taret hazırlık
                elif vehicle_speed > 35.0:
                    current_event = 2  # Sürü İHA tehdit sektörü
                else:
                    current_event = random.choice([0, 1, 5])
            else:
                if now - last_event_time > 1.5 and current_event != 0:
                    current_event = 0

            # Paketi oluştur (Little-Endian)
            packet_data = struct.pack(
                PACKET_FORMAT,
                float(avionics_temp),
                float(bus_voltage),
                float(vehicle_speed),
                int(defense_readiness),
                float(target_x),
                float(target_y),
                int(current_event)
            )

            sock.sendto(packet_data, (UDP_IP, UDP_PORT))

            if step % 10 == 0:
                print(
                    f"[{time.strftime('%H:%M:%S')}] "
                    f"Aviyonik: {avionics_temp:5.1f}°C | "
                    f"Batarya: {bus_voltage:5.2f} V | "
                    f"İKA Hızı: {vehicle_speed:4.1f} km/s | "
                    f"Hazırlık: %{defense_readiness:3d} | "
                    f"Tehdit: ({target_x:+.2f}, {target_y:+.2f}) | "
                    f"Olay: {current_event}"
                )

            step += 1
            time.sleep(INTERVAL)

    except KeyboardInterrupt:
        print("\n[!] Simülasyon durduruldu.")
    finally:
        sock.close()

if __name__ == "__main__":
    main()
