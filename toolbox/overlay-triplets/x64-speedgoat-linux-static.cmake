set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# Linkage preferences
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static) # common for embedded

# Preserve the SDK paths used to locate the relocatable cross-compilers.
# On Windows, the setup script exports these paths in 8.3 form, which keeps
# GCC's internally constructed header paths below the legacy MAX_PATH limit.
set(VCPKG_ENV_PASSTHROUGH
    OECORE_NATIVE_SYSROOT
    PATH
    SDKTARGETSYSROOT
    TARGET_PREFIX)

# Absolute path to the chainloaded toolchain
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_LIST_DIR}/speedgoat-linux-toolchain.cmake")

# Disable debug builds
set(VCPKG_BUILD_TYPE release)
