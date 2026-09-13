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
#
# Prefer the short native-sysroot path exported by the Speedgoat SDK setup
# script. Resolving the compiler from PATH expands it to a long path on
# Windows, which can prevent relocatable GCC from finding include-fixed.
string(REPLACE "\"" "" SPEEDGOAT_NATIVE_SYSROOT "$ENV{OECORE_NATIVE_SYSROOT}")
file(TO_CMAKE_PATH "${SPEEDGOAT_NATIVE_SYSROOT}" SPEEDGOAT_NATIVE_SYSROOT)
set(SPEEDGOAT_TARGET_PREFIX "$ENV{TARGET_PREFIX}")
string(REGEX REPLACE "-$" "" SPEEDGOAT_TARGET_DIRECTORY "${SPEEDGOAT_TARGET_PREFIX}")

if(SPEEDGOAT_NATIVE_SYSROOT AND SPEEDGOAT_TARGET_PREFIX)
    set(SPEEDGOAT_COMPILER_DIRECTORY
        "${SPEEDGOAT_NATIVE_SYSROOT}/usr/bin/${SPEEDGOAT_TARGET_DIRECTORY}")
    set(SPEEDGOAT_COMPILER_SUFFIX "")
    if(CMAKE_HOST_WIN32)
        set(SPEEDGOAT_COMPILER_SUFFIX ".exe")
    endif()

    set(CMAKE_C_COMPILER
        "${SPEEDGOAT_COMPILER_DIRECTORY}/${SPEEDGOAT_TARGET_PREFIX}gcc${SPEEDGOAT_COMPILER_SUFFIX}"
        CACHE FILEPATH "")
    set(CMAKE_CXX_COMPILER
        "${SPEEDGOAT_COMPILER_DIRECTORY}/${SPEEDGOAT_TARGET_PREFIX}g++${SPEEDGOAT_COMPILER_SUFFIX}"
        CACHE FILEPATH "")
else()
    set(CMAKE_C_COMPILER ${CMAKE_SYSTEM_PROCESSOR}-speedgoat-linux-gcc CACHE FILEPATH "")
    set(CMAKE_CXX_COMPILER ${CMAKE_SYSTEM_PROCESSOR}-speedgoat-linux-g++ CACHE FILEPATH "")
endif()

# Sysroot
string(REPLACE "\"" "" SDKTARGETSYSROOT "$ENV{SDKTARGETSYSROOT}")
if(SDKTARGETSYSROOT STREQUAL "")
    message(FATAL_ERROR "SDKTARGETSYSROOT is not set. Run the Speedgoat toolchain setup script first.")
endif()
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
