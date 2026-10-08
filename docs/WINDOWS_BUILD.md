# ALAZ SCADA Telemetri - Windows Derleme ve Dağıtım Kılavuzu

Bu belge, **ALAZ Çelik Kubbe Hava Savunma & İKA Komuta Kontrol Telemetri** projesinin Windows hedefi için hem **Linux (Arch Linux / CachyOS) üzerinden cross-compile** hem de **yerel Windows makinesinde (Native Build)** derlenmesi ve `dist/windows` bağımsız dağıtım paketinin oluşturulması adımlarını açıklar.

---

## 1. Platform ve Kod Uyumluluk Mimarisi

Proje kod tabanı Linux ve Windows arasında %100 taşınabilir olacak şekilde standartlaştırılmıştır:

- **Konsol Penceresini Engelleme (`WIN32_EXECUTABLE`):** Windows GUI uygulamalarında arkada siyah bir CMD penceresi açılmaması için `CMakeLists.txt` içerisinde `WIN32_EXECUTABLE TRUE` hedef özelliği tanımlanmıştır.
- **Ağ ve Soket Soyutlaması:** UDP haberleşmesinde Qt'nin `QUdpSocket` sınıfı kullanılmaktadır. Windows soket altyapısı (`WSAStartup` ve `WSACleanup`), Qt ağ motoru tarafından otomatik olarak yönetilir. MinGW ve statik bağlama senaryoları için `ws2_32` kütüphanesi `CMakeLists.txt` üzerinden güvence altına alınmıştır.
- **İki Boyutlu Bellek Hizalaması (`#pragma pack` ve GCC Packed):** `common/TelemetryData.h` içerisindeki 22-baytlık `TelemetryPacket` yapısı, hem MSVC (`#pragma pack(push, 1)`) hem de GCC/MinGW (`__attribute__((packed))`) direktifleri ile derleyici dolgularından (padding) arındırılmıştır ve `static_assert(sizeof(...) == 22)` ile derleme anında doğrulanır.
- **Font Geri Çekilme (Fallback) Desteği:** Sistemde `JetBrainsMono Nerd Font` bulunmadığı durumlarda Windows'ta otomatik olarak `Consolas`, Linux'ta ise `Monospace` fontuna düşülür.

---

## 2. Linux (CachyOS / Arch Linux) Üzerinden Cross-Compile

MinGW veya Qt derleyicilerini kaynak koddan derlemekle vakit kaybetmemeniz için **3 farklı ve hızlı yöntem** sunulmuştur:

### 2.1. Yöntem 1: Docker ile Tek Komutla Derleme (En Zahmetsiz Yerel Yöntem - 0 sn Kurulum)

Sisteminizde Docker zaten kurulu ve aktif olduğu için, Fedora'nın resmi depolarında yer alan hazır MinGW Qt6 paketlerini kullanan otomatik scripti çalıştırabilirsiniz:

```bash
./build_with_docker.sh
```

**Bu script:**
- İlk çalıştırmada Fedora tabanlı hazır derleme imajını çeker (sıfır derleyici derleme).
- `telemetri_ui.exe` dosyasını derleyip doğrudan `dist/windows/telemetri_ui.exe` konumuna yerleştirir.

---

### 2.2. Yöntem 2: Arch Pacman Precompiled Binary Deposu (`[ownstuff]`)

> [!TIP]
> AUR üzerinden `mingw-w64-qt6-*` paketlerini kaynak koddan derlemeye çalışmak; Rust, LLVM, librsvg gibi devasa kütüphanelerin sıfırdan derlenmesini gerektirir. Bu hem saatler sürer hem de bağlantı kesilmelerine (`Connection reset by peer`) yol açabilir.
>
> Bu paketlerin resmi geliştiricisi olan **Martchus**, paketlerin önceden derlenmiş ikili (binary) hallerini **`[ownstuff]`** deposunda yayınlamaktadır.

#### 1. Depoyu `/etc/pacman.conf` Dosyasına Ekleyin:
```ini
[ownstuff]
SigLevel = Optional TrustAll
Server = https://martchus.no-ip.biz/repo/arch/ownstuff/os/$arch
```

#### 2. Doğrudan Pacman ile Saniyeler İçinde Kurun:
```bash
sudo pacman -Sy
sudo pacman -S --needed \
    mingw-w64-gcc \
    mingw-w64-cmake \
    mingw-w64-qt6-base \
    mingw-w64-qt6-declarative \
    mingw-w64-qt6-charts
```

*(Eğer depoyu eklemeden sadece AUR kullanmak isterseniz `paru -S mingw-w64-qt6-base ...` çalıştırabilirsiniz, ancak yukarıdaki precompiled depo ile işlem 15 saniyede tamamlanır).*

### 2.2. Yöntem A: `x86_64-w64-mingw32-cmake` ile Derleme (Önerilen)
`mingw-w64-cmake` paketi kurulduktan sonra Arch/CachyOS ortamında hazır gelen wrapper komutu kullanabilirsiniz:

```bash
# 1. Proje kök dizinine geçin
cd /home/eigen/Projects/telemetriui

# 2. Windows 64-bit için yapılandırın
x86_64-w64-mingw32-cmake -B build-win -S . -DCMAKE_BUILD_TYPE=Release

# 3. Derleyin
cmake --build build-win --parallel
```

### 2.3. Yöntem B: Depodaki Toolchain Dosyası ile Derleme
Depoda yer alan `cmake/mingw-w64-x86_64.cmake` dosyasını kullanarak doğrudan standart `cmake` ile de derleyebilirsiniz:

```bash
cmake -B build-win -S . \
    -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build-win --parallel
```

Derleme tamamlandığında Windows çalıştırılabilir dosyası `build-win/telemetri_ui.exe` konumunda üretilir.

---

## 3. Yerel Windows Ortamında Derleme (Native Build)

Windows 10 veya Windows 11 makinesinde Visual Studio (MSVC) veya MinGW kurulu bir ortamda projeyi derleme yöntemleri:

### 3.1. Ön Gereksinimler
1. **CMake (3.16 veya üzeri):** [cmake.org/download](https://cmake.org/download/) veya `winget install Kitware.CMake`
2. **Derleyici:**
   - Visual Studio 2019 veya 2022 ("Desktop development with C++" bileşeni seçili) **VEYA**
   - MinGW-w64 64-bit
3. **Qt 6 (Qt 6.5+):**
   - Qt Online Installer ile kurulu:
     - `Qt 6.x.x` -> `MSVC 2019/2022 64-bit` (veya `MinGW 64-bit`)
     - Ek modüller: `Qt Charts`, `Qt Quick Timeline` vb.
4. **Python 3:** UDP mock paket göndericisi (`mock_sender.py`) testi için.

---

### 3.2. Tek Tıkla Otomatik Derleme ve Dağıtım (Önerilen)

Proje kök dizininde hazır bulunan dağıtım scriptlerini kullanabilirsiniz:

#### Batch Dosyası ile (`build_windows.bat`):
Windows Gezgini'nde **`build_windows.bat`** dosyasına **çift tıklayın** ya da CMD konsolundan çalıştırın:
```cmd
build_windows.bat
```

#### PowerShell ile (`build_windows.ps1`):
PowerShell penceresinde:
```powershell
.\build_windows.ps1 -BuildType Release
```

**Scriptler Sırasıyla Neler Yapar?**
1. Visual Studio MSVC ortamını (`vcvars64.bat`) ve `cmake.exe` varlığını tespit eder.
2. Qt6 dizinini ve `windeployqt.exe` aracını tarar, ortam değişkenlerine ekler.
3. `build_windows/` dizininde Release konfigürasyonunda derlemeyi tamamlar.
4. Çıktı `telemetri_ui.exe` dosyasını `dist/windows/` dizinine kopyalar.
5. **`windeployqt --release --qmldir .`** komutunu işleterek;
   - Qt6 Gui, Network, Charts, Core DLL'lerini,
   - QML motoru eklentilerini (`QtQuick`, `QtQuick.Controls`, `QtQuick.Shapes`, `QtCharts`),
   - C++ Runtime kütüphanelerini (`vcruntime140.dll`, `msvcp140.dll` vb.)
   bağımsız çalışabilecek şekilde `dist/windows/` içerisine toplar.
6. UDP test scripti `mock_sender.py` dosyasını `dist/windows/` içine kopyalar.

---

### 3.3. Manuel Adım Adım Derleme ve `windeployqt` Dağıtımı

Otomasyon scripti kullanmadan adım adım derlemek isterseniz:

#### Adım 1: Geliştirici Konsolunu Açın
- **MSVC Kullanıyorsanız:** Başlat menüsünden *"x64 Native Tools Command Prompt for VS 2022"* konsolunu açın.
- **MinGW Kullanıyorsanız:** MinGW ve Qt `bin` klasörleri PATH'e eklenmiş bir CMD açın.

#### Adım 2: CMake ile Yapılandırın ve Derleyin
```cmd
cd C:\yol\telemetriui
cmake -B build_windows -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build_windows --config Release --parallel
```

#### Adım 3: Dağıtım Klasörünü Hazırlayın
```cmd
mkdir dist\windows
copy build_windows\Release\telemetri_ui.exe dist\windows\
copy mock_sender.py dist\windows\
```
*(Eğer MinGW veya Ninja kullandıysanız dosya `build_windows\telemetri_ui.exe` konumunda olacaktır).*

#### Adım 4: windeployqt ile Bağımlılıkları Paketleyin
```cmd
windeployqt.exe --release --qmldir . --compiler-runtime --no-translations dist\windows\telemetri_ui.exe
```

> **Önemli:** `--qmldir .` parametresi zorunludur! Bu parametre olmadan windeployqt QML dosyalarınızda kullanılan `QtCharts` ve `QtQuick.Shapes` eklentilerini tespit edemez ve uygulama açılışta `module "QtCharts" is not installed` hatası verir.

---

## 4. Test ve Çalıştırma

Dağıtım paketi hazırlandıktan sonra herhangi bir geliştirme ortamı (Qt/VS) kurulu olmayan temiz bir Windows makinesine `dist/windows` klasörünü kopyalayarak doğrudan çalıştırabilirsiniz.

1. **Arayüzü Başlatın:**
   ```cmd
   dist\windows\telemetri_ui.exe
   ```
2. **Telemetri Simülasyonunu Başlatın (Ayrı bir CMD ekranında):**
   ```cmd
   python dist\windows\mock_sender.py
   ```

Arayüz saniyede 10 paket sıklıkla Çelik Kubbe & İKA telemetri verilerini alacak, göstergeler animasyonlu renk geçişleriyle güncellenecektir.
