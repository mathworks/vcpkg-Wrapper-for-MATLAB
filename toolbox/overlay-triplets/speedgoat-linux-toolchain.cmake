# speedgoat-linux-toolchain.cmake

# Require a modern-enough CMake
cmake_minimum_required(VERSION 3.20)

# Tell CMake we target Linux
set(CMAKE_SYSTEM_NAME Linux CACHE STRING "")

# Set target processor
if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
     set(CMAKE_SYSTEM_PROCESSOR x86_64 CACHE STRING "")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
     set(CMAKE_SYSTEM_PROCESSOR i686 CACHE STRING "")
     string(APPEND VCPKG_C_FLAGS " -m32")
     string(APPEND VCPKG_CXX_FLAGS " -m32")
     string(APPEND VCPKG_LINKER_FLAGS " -m32")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
     set(CMAKE_SYSTEM_PROCESSOR armv7l CACHE STRING "")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
     set(CMAKE_SYSTEM_PROCESSOR aarch64 CACHE STRING "")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "riscv64")
     set(CMAKE_SYSTEM_PROCESSOR riscv64 CACHE STRING "")
endif()

# Compilers
set(CMAKE_C_COMPILER ${CMAKE_SYSTEM_PROCESSOR}-speedgoat-linux-gcc CACHE FILEPATH "")
set(CMAKE_CXX_COMPILER ${CMAKE_SYSTEM_PROCESSOR}-speedgoat-linux-g++ CACHE FILEPATH "")

# Sysroot
string(REPLACE "\"" "" SDKTARGETSYSROOT "$ENV{SDKTARGETSYSROOT}")
set(CMAKE_SYSROOT ${SDKTARGETSYSROOT} CACHE PATH "")
set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT} CACHE PATH "")

# Optimize for target architecture
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    add_compile_options(-march=core2)
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
    add_compile_options(-march=armv8-a+crc)
else()
    message(FATAL_ERROR "Unsupported processor architecture='${CMAKE_SYSTEM_PROCESSOR}'. Use aarch64|x86_64.")
endif()

# Host tools only (executables used during configure/build)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Target artifacts only (resolved via sysroot / root path)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
