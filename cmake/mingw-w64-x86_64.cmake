# ==============================================================================
# MinGW-w64 x86_64 CMake Toolchain Dosyası
# Arch Linux / CachyOS üzerinden Windows x86_64 Cross-Compile için yapılandırma
# ==============================================================================

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# MinGW-w64 Araç Zinciri Ön Eki
set(TOOLCHAIN_PREFIX x86_64-w64-mingw32)

set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}-g++)
set(CMAKE_RC_COMPILER ${TOOLCHAIN_PREFIX}-windres)

# Hedef ortam kök dizini (Arch/CachyOS: /usr/x86_64-w64-mingw32)
set(CMAKE_FIND_ROOT_PATH /usr/${TOOLCHAIN_PREFIX})

# Arama stratejileri:
# Programları ana makineden (host), kütüphane ve başlıkları hedef sistemden (target) ara
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# MinGW Qt6 kütüphane yolu (mingw-w64-qt6 paketleri /usr/x86_64-w64-mingw32 altına kurulur)
list(APPEND CMAKE_PREFIX_PATH /usr/${TOOLCHAIN_PREFIX})
