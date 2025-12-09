# triplets/x64-qnx-static.cmake
# Custom vcpkg triplet for QNX x86_64 (ntox86_64)
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CMAKE_SYSTEM_NAME QNX)

# Linkage preferences (adjust per your deployment)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static) # common for embedded/QNX

# Pass environment variables
set(VCPKG_ENV_PASSTHROUGH QNX_HOST;QNX_TARGET;QNX_BASE;PATH)

# Absolute path to the chainloaded toolchain
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_LIST_DIR}/qnx-toolchain.cmake")

# Pass the target arch down to the toolchain
set(VCPKG_CMAKE_CONFIGURE_OPTIONS
    "-DQNX_ARCH=x86_64"
)

# Disable debug builds
set(VCPKG_BUILD_TYPE release)