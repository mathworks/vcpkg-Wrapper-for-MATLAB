# qnx-toolchain.cmake
# Purpose: Define compilers, sysroot, and flags for QNX builds via qcc/q++.

# Require a modern-enough CMake (QNX platform is supported natively)
cmake_minimum_required(VERSION 3.20)

# Tell CMake we target QNX
set(CMAKE_SYSTEM_NAME QNX CACHE STRING "")

# Expect QNX env to be sourced, so QNX_HOST and QNX_TARGET exist
if(NOT DEFINED ENV{QNX_HOST} OR NOT DEFINED ENV{QNX_TARGET})
    message(FATAL_ERROR "QNX environment not found. Please 'source qnxsdp-env.sh' first.")
endif()

# Allow caller to choose architecture; default to x86_64
if(DEFINED QNX_ARCH)
    set(CMAKE_SYSTEM_PROCESSOR "${QNX_ARCH}" CACHE STRING "QNX target arch (aarch64|armv7|x86_64)")
else()
    set(CMAKE_SYSTEM_PROCESSOR "x86_64" CACHE STRING "QNX target arch (aarch64|armv7|x86_64)")
endif()

# Map arch → qcc variant string and sysroot suffix
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
    set(QNX_QCC_VARIANT "gcc_ntoaarch64le_gpp")
    set(QNX_SYSROOT_SUFFIX "aarch64le")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7")
    set(QNX_QCC_VARIANT "gcc_ntoarmv7le_gpp")
    set(QNX_SYSROOT_SUFFIX "armle-v7")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    set(QNX_QCC_VARIANT "gcc_ntox86_64_gpp")
    set(QNX_SYSROOT_SUFFIX "x86_64")
else()
    message(FATAL_ERROR "Unsupported processor architecture='${CMAKE_SYSTEM_PROCESSOR}'. Use aarch64|armv7|x86_64.")
endif()

# Compilers (use qcc/q++ so the -V variant selects the right GCC/binutils under the hood)
set(CMAKE_C_COMPILER qcc CACHE FILEPATH "")
set(CMAKE_C_COMPILER_TARGET ${QNX_QCC_VARIANT})
set(CMAKE_CXX_COMPILER q++ CACHE FILEPATH "")
set(CMAKE_CXX_COMPILER_TARGET ${QNX_QCC_VARIANT})

# Sysroot. For QNX, the headers/libs live under $QNX_TARGET/<arch>
# Examples:
#   $QNX_TARGET/aarch64le
#   $QNX_TARGET/armle-v7
#   $QNX_TARGET/x86_64
set(CMAKE_SYSROOT $ENV{QNX_TARGET} CACHE PATH "")
set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT} CACHE PATH "")

# Add additional paths
set(CMAKE_PREFIX_PATH ${CMAKE_SYSROOT}/${QNX_SYSROOT_SUFFIX}; ${CMAKE_SYSROOT}/${QNX_SYSROOT_SUFFIX}/usr)

# Host tools only (executables used during configure/build)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Target artifacts only (resolved via sysroot / root path)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Optional: if some projects try to use GNU ar/ranlib/nm directly, point to QNX tools
# But usually qcc/q++ + -V variant is enough.
# set(CMAKE_AR      "nto${QNX_SYSROOT_SUFFIX}-ar")
# set(CMAKE_RANLIB  "nto${QNX_SYSROOT_SUFFIX}-ranlib")
# set(CMAKE_NM      "nto${QNX_SYSROOT_SUFFIX}-nm")

# QNX doesn't use glibc; some ports may need feature tests or POSIX settings.
add_compile_definitions(_QNX_SOURCE)
add_compile_definitions(__GNU__)
