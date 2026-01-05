# speedgoat-linux-toolchain.cmake

# Require a modern-enough CMake
cmake_minimum_required(VERSION 3.20)

# Tell CMake we target Linux
set(CMAKE_SYSTEM_NAME Linux)

# Allow caller to choose architecture; default to x86_64
set(CMAKE_SYSTEM_PROCESSOR "x86_64" CACHE STRING "Speedgoat Linux target arch (aarch64|x86_64)")

# Compilers
set(CMAKE_C_COMPILER ${CMAKE_SYSTEM_PROCESSOR}-speedgoat-linux-gcc)
set(CMAKE_CXX_COMPILER ${CMAKE_SYSTEM_PROCESSOR}-speedgoat-linux-g++)

# Sysroot
set(CMAKE_SYSROOT "$ENV{SDKTARGETSYSROOT}")

# Optimize for target architecture
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    add_compile_options(-march=core2)
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
    add_compile_options(-march=armv8-a+crc)
else()
    message(FATAL_ERROR "Unsupported processor architecture='${CMAKE_SYSTEM_PROCESSOR}'. Use aarch64|x86_64.")
endif()

# Make sure CMake finds things in the sysroot first
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

# Set fPIC flag
set(CMAKE_POSITION_INDEPENDENT_CODE ON)