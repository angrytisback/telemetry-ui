@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
:: ALAZ Takımı - SCADA Telemetri Arayüzü Windows Yerel Derleme ve Dağıtım Scripti
:: Desteklenen Derleyiciler: MSVC (Visual Studio 2019/2022) veya MinGW-w64 (Qt6)
:: ==============================================================================

chcp 65001 >nul
echo ==============================================================================
echo [ALAZ SCADA] Windows Yerel Derleme ve Dagitim Baslatiliyor...
echo ==============================================================================

set "PROJECT_ROOT=%~dp0"
set "BUILD_DIR=%PROJECT_ROOT%build_windows"
set "DIST_DIR=%PROJECT_ROOT%dist\windows"

:: 1. Visual Studio MSVC Ortamini Tespit Et (gerekirse vcvars64.bat calistir)
where cl.exe >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [*] MSVC cl.exe PATH icinde bulunamadi, Visual Studio vcvars64 araniyor...
    set "VS_WHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
    if exist "!VS_WHERE!" (
        for /f "usebackq tokens=*" %%i in (`"!VS_WHERE!" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
            set "VS_INSTALL_DIR=%%i"
        )
    )
    if defined VS_INSTALL_DIR (
        if exist "!VS_INSTALL_DIR!\VC\Auxiliary\Build\vcvars64.bat" (
            echo [*] Visual Studio 64-bit ortami yukleniyor: !VS_INSTALL_DIR!
            call "!VS_INSTALL_DIR!\VC\Auxiliary\Build\vcvars64.bat" >nul
        )
    )
)

:: 2. CMake Kontrolu
where cmake.exe >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [HATA] 'cmake.exe' sistem PATH icerisinde bulunamadi!
    echo Lutfen CMake kurun veya PATH ortam degiskenine ekleyin.
    pause
    exit /b 1
)

:: 3. Qt6 ve windeployqt Kontrolu
where windeployqt.exe >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [*] windeployqt PATH icinde bulunamadi, varsayilan C:\Qt konumlari araniyor...
    for /d %%D in (C:\Qt\6.*) do (
        if exist "%%D\msvc2019_64\bin\windeployqt.exe" (
            set "QT_BIN_DIR=%%D\msvc2019_64\bin"
        ) else if exist "%%D\msvc2022_64\bin\windeployqt.exe" (
            set "QT_BIN_DIR=%%D\msvc2022_64\bin"
        ) else if exist "%%D\mingw_64\bin\windeployqt.exe" (
            set "QT_BIN_DIR=%%D\mingw_64\bin"
        )
    )
    if defined QT_BIN_DIR (
        echo [*] Qt6 bulundu: !QT_BIN_DIR!
        set "PATH=!QT_BIN_DIR!;!PATH!"
    ) else (
        echo [BILGI] windeployqt.exe otomatik bulunamadi. Qt ortam degiskenlerinizin tanimli oldugundan emin olun.
    )
)

:: 4. Derleme Dizinini Hazirla
echo [*] Derleme dizini hazirlaniyor: %BUILD_DIR%
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

:: 5. CMake Yapilandirma
echo [*] CMake yapilandiriliyor (Release)...
cmake -B "%BUILD_DIR%" -S "%PROJECT_ROOT%" -DCMAKE_BUILD_TYPE=Release
if %ERRORLEVEL% NEQ 0 (
    echo [HATA] CMake yapilandirmasi basarisiz oldu!
    pause
    exit /b 1
)

:: 6. Projeyi Derle
echo [*] Proje derleniyor (parallel)...
cmake --build "%BUILD_DIR%" --config Release --parallel
if %ERRORLEVEL% NEQ 0 (
    echo [HATA] Proje derlenemedi!
    pause
    exit /b 1
)

:: 7. .exe Dosyasini Tespit Et
set "TARGET_EXE="
if exist "%BUILD_DIR%\Release\telemetri_ui.exe" (
    set "TARGET_EXE=%BUILD_DIR%\Release\telemetri_ui.exe"
) else if exist "%BUILD_DIR%\telemetri_ui.exe" (
    set "TARGET_EXE=%BUILD_DIR%\telemetri_ui.exe"
)

if not defined TARGET_EXE (
    echo [HATA] Derlenen 'telemetri_ui.exe' dosyasi bulunamadi!
    pause
    exit /b 1
)

:: 8. Dagitim (dist\windows) Dizinini Hazirla
echo [*] Dagitim paketi olusturuluyor: %DIST_DIR%
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

copy /y "%TARGET_EXE%" "%DIST_DIR%\telemetri_ui.exe" >nul
if exist "%PROJECT_ROOT%mock_sender.py" (
    copy /y "%PROJECT_ROOT%mock_sender.py" "%DIST_DIR%\mock_sender.py" >nul
)

:: 9. windeployqt ile Tum Qt6 DLL, QML Eklentileri ve Bagimliliklari Kopyala
where windeployqt.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [*] windeployqt calistiriliyor (QML modulleri ve Qt6 bilesenleri paketleniyor)...
    windeployqt.exe --release --qmldir "%PROJECT_ROOT%" --compiler-runtime --no-translations "%DIST_DIR%\telemetri_ui.exe"
    if %ERRORLEVEL% NEQ 0 (
        echo [UYARI] windeployqt bazi uyarilar dondurdu, ancak paketleme devam etti.
    )
) else (
    echo [UYARI] windeployqt.exe sistemde bulunamadigi icin DLL kopyalama adimi atlandi.
)

echo ==============================================================================
echo [BASARILI] ALAZ SCADA Telemetri Windows Paketi Hazir!
echo Konum: %DIST_DIR%
echo Calistirma: %DIST_DIR%\telemetri_ui.exe
echo Test Icin: python %DIST_DIR%\mock_sender.py
echo ==============================================================================

pause
