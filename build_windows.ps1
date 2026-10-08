<#
.SYNOPSIS
    ALAZ Takımı SCADA Telemetri Windows Yerel Derleme ve Dağıtım PowerShell Scripti.
.DESCRIPTION
    Qt6, CMake ve MSVC/MinGW araçlarını kullanarak telemetri_ui projesini Release modunda derler
    ve windeployqt ile tüm bağımlılıkları dist/windows klasörüne paketler.
.PARAMETER BuildType
    Derleme tipi: Release veya Debug (Varsayılan: Release)
.PARAMETER Clean
    Derleme dizinini sıfırdan temizler.
#>

[CmdletBinding()]
param(
    [string]$BuildType = "Release",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$BuildDir = Join-Path $ProjectRoot "build_windows"
$DistDir = Join-Path $ProjectRoot "dist\windows"

Write-Host "==============================================================================" -ForegroundColor Red
Write-Host " [ALAZ SCADA] Windows Yerel Derleme ve Dağıtım (PowerShell)" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Red

# 1. Temizlik Talebi
if ($Clean -and (Test-Path $BuildDir)) {
    Write-Host "[*] Temiz derleme: $BuildDir temizleniyor..." -ForegroundColor Yellow
    Remove-Item -Path $BuildDir -Recurse -Force
}

# 2. CMake Kontrolü
if (-not (Get-Command "cmake" -ErrorAction SilentlyContinue)) {
    Write-Error "[HATA] 'cmake' sistem PATH içerisinde bulunamadı! Lütfen CMake yükleyin."
}

# 3. Qt6 ve windeployqt Ortamını Doğrula
$windeployqt = Get-Command "windeployqt" -ErrorAction SilentlyContinue
if (-not $windeployqt) {
    Write-Host "[*] windeployqt PATH içinde bulunamadı, C:\Qt konumları taranıyor..." -ForegroundColor Yellow
    $qtPaths = Get-ChildItem -Path "C:\Qt\6.*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Join-Path $_.FullName "msvc2019_64\bin"
        Join-Path $_.FullName "msvc2022_64\bin"
        Join-Path $_.FullName "mingw_64\bin"
    } | Where-Object { Test-Path (Join-Path $_ "windeployqt.exe") }

    if ($qtPaths.Count -gt 0) {
        $qtBin = $qtPaths[0]
        Write-Host "[*] Qt6 bulundu: $qtBin" -ForegroundColor Green
        $env:PATH = "$qtBin;$env:PATH"
    } else {
        Write-Host "[BİLGİ] windeployqt otomatik bulunamadı. Qt ortam değişkenlerinizin tanımlı olduğundan emin olun." -ForegroundColor Yellow
    }
}

# 4. Derleme Dizinini Oluştur
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir | Out-Null
}

# 5. CMake Yapılandır
Write-Host "[*] CMake yapılandırılıyor ($BuildType)..." -ForegroundColor Cyan
& cmake -B $BuildDir -S $ProjectRoot -DCMAKE_BUILD_TYPE=$BuildType
if ($LASTEXITCODE -ne 0) {
    Write-Error "[HATA] CMake yapılandırması başarısız oldu!"
}

# 6. Projeyi Derle
Write-Host "[*] Proje derleniyor..." -ForegroundColor Cyan
& cmake --build $BuildDir --config $BuildType --parallel
if ($LASTEXITCODE -ne 0) {
    Write-Error "[HATA] Proje derlenemedi!"
}

# 7. Çıktı Dosyasını (.exe) Bul
$exeCandidates = @(
    (Join-Path $BuildDir "$BuildType\telemetri_ui.exe"),
    (Join-Path $BuildDir "telemetri_ui.exe")
)
$targetExe = $exeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $targetExe) {
    Write-Error "[HATA] Derlenen 'telemetri_ui.exe' dosyası bulunamadı!"
}

# 8. Dağıtım Klasörünü Hazırla (dist/windows)
Write-Host "[*] Dağıtım paketi oluşturuluyor: $DistDir" -ForegroundColor Cyan
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
}

Copy-Item -Path $targetExe -Destination (Join-Path $DistDir "telemetri_ui.exe") -Force
$mockSender = Join-Path $ProjectRoot "mock_sender.py"
if (Test-Path $mockSender) {
    Copy-Item -Path $mockSender -Destination (Join-Path $DistDir "mock_sender.py") -Force
}

# 9. windeployqt ile Bağımlılıkları Dağıt
if (Get-Command "windeployqt" -ErrorAction SilentlyContinue) {
    Write-Host "[*] windeployqt çalıştırılıyor (QML bileşenleri ve Qt6 DLL'leri toplanıyor)..." -ForegroundColor Green
    & windeployqt --release --qmldir $ProjectRoot --compiler-runtime --no-translations (Join-Path $DistDir "telemetri_ui.exe")
} else {
    Write-Host "[UYARI] windeployqt bulunamadığı için DLL kopyalama adımı atlandı." -ForegroundColor Yellow
}

Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "[BAŞARILI] ALAZ SCADA Telemetri Windows Paketi Hazır!" -ForegroundColor Green
Write-Host "Konum: $DistDir" -ForegroundColor White
Write-Host "Çalıştırma: $(Join-Path $DistDir 'telemetri_ui.exe')" -ForegroundColor Yellow
Write-Host "Test İçin: python $(Join-Path $DistDir 'mock_sender.py')" -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor Green
