set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# Linkage preferences
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static) # common for embedded

# Pass environment variables
set(VCPKG_ENV_PASSTHROUGH SDKTARGETSYSROOT;PATH)

# Absolute path to the chainloaded toolchain
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_LIST_DIR}/speedgoat-linux-toolchain.cmake")

# Disable debug builds
set(VCPKG_BUILD_TYPE release)