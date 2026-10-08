#!/usr/bin/env bash
set -e

# ==============================================================================
# ALAZ SCADA - Docker ile Windows Cross-Compile (Sıfır Derleyici Derleme)
# Önceden derlenmiş resmi Fedora MinGW-Qt6 depolarını kullanarak saniyeler içinde
# Windows .exe çıktısı üretir.
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="alaz-telemetri-win-builder"

echo "=============================================================================="
echo " [ALAZ SCADA] Docker ile Windows .exe Derleme Başlatılıyor..."
echo "=============================================================================="

# 1. Hazır Derleme İmajını Kontrol Et / Oluştur
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "[*] Derleyici ortamı imajı oluşturuluyor (yalnızca ilk seferde 1-2 dk sürer)..."
    docker build -t "$IMAGE_NAME" -f "$PROJECT_ROOT/docker/Dockerfile.windows" "$PROJECT_ROOT"
fi

# 2. Konteyner İçinde Derlemeyi Çalıştır
echo "[*] Windows .exe derleniyor..."
docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$PROJECT_ROOT:/src" \
    -w /src \
    "$IMAGE_NAME" \
    bash -c '
        set -e
        mkdir -p build-docker-win dist/windows
        mingw64-cmake -B build-docker-win -S . -DCMAKE_BUILD_TYPE=Release -G Ninja
        cmake --build build-docker-win --parallel
        cp build-docker-win/telemetri_ui.exe dist/windows/telemetri_ui.exe
        if [ -f mock_sender.py ]; then
            cp mock_sender.py dist/windows/mock_sender.py
        fi
        echo "[+] telemetri_ui.exe derlendi ve dist/windows klasörüne kopyalandı."
    '

echo "=============================================================================="
echo " [BAŞARILI] Windows Çalıştırılabilir Dosyası Hazır!"
echo " Konum: $PROJECT_ROOT/dist/windows/telemetri_ui.exe"
echo "=============================================================================="
