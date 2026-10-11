# vcpkg Wrapper for MATLAB&reg;

[![View vcpkg Wrapper for MATLAB on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/182780-vcpkg-wrapper-for-matlab)

This simple toolbox wraps [vcpkg - Open source C/C++ dependency manager from Microsoft&reg;](https://vcpkg.io/en/index.html) to ease the integration into MATLAB projects that use vcpkg [manifest mode](https://learn.microsoft.com/en-us/vcpkg/concepts/manifest-mode) to define its dependencies.
The wrapper toolbox figures out the host and target triplets as well as the compiler paths automatically. It only requires vcpkg to be available on the system's path.

## Setup
Download toolbox installer from releases in GitHub or File Exchange and install in MATLAB.

### MathWorks Products (https://www.mathworks.com)
Requires MATLAB release R2020b or newer
- [MATLAB&reg;](https://www.mathworks.com/products/matlab.html)

### 3rd Party Products
- [vcpkg](https://github.com/microsoft/vcpkg)

## Getting started
The instructions for use are located in the [Getting Started documentation](toolbox/gettingStarted.mlx) and are part of the shipping toolbox.

### Dynamic and static builds
Host libraries are built dynamically by default, preferring a Release-only triplet when available. Set the optional scalar logical argument `buildDynamic` to `false` to build static host libraries. Supported embedded target builds always use static libraries, regardless of this option.

```matlab
% Build dynamic host libraries only (the default linkage).
vcpkg.buildVcpkgDeps('path/to/manifest', 'buildHostOnly', true)

% Build static host libraries only.
vcpkg.buildVcpkgDeps('path/to/manifest', ...
    'buildHostOnly', true, 'buildDynamic', false)

% Build dynamic host dependencies and static embedded target libraries.
vcpkg.buildVcpkgDeps('path/to/manifest')
```

When no supported embedded target is detected, dependencies are built for the host using the selected linkage. Host builds explicitly select the same triplet for both `--triplet` and `--host-triplet`.

`vcpkg.getHostTriplet()` selects dynamic host libraries with a preference for Release-only builds; `vcpkg.getHostTriplet(false)` selects static Release-only host libraries. Host triplets come from the installed vcpkg's `triplets` and `triplets/community` folders:

| Host/compiler | Dynamic (default) | Static |
| --- | --- | --- |
| Windows / MSVC | `x64-windows-release` if available, otherwise `x64-windows` | `x64-windows-static-md-release` |
| Windows / MinGW | `x64-mingw-dynamic-release` | `x64-mingw-static-release` |
| Linux | `x64-linux-dynamic-release` if available, otherwise `x64-linux-dynamic` | `x64-linux-release` |
| macOS / Intel | `x64-osx-dynamic-release` if available, otherwise `x64-osx-dynamic` | `x64-osx-release` |
| macOS / Apple silicon | `arm64-osx-dynamic-release` if available, otherwise `arm64-osx-dynamic` | `arm64-osx-release` |

Applications using dynamic libraries must make the corresponding shared libraries available at runtime.

Both `buildDynamic` and `buildRelease` accept scalar values that MATLAB converts to logical. Numeric `0` selects `false`; nonzero numeric values select `true`.

### Release-only builds
The optional scalar logical argument `buildRelease` defaults to `true`, selecting a matching host triplet ending in `-release` when available. These triplets set `VCPKG_BUILD_TYPE` to `release` and skip Debug libraries. If no dynamic Release triplet exists in the installed vcpkg, the wrapper warns and uses the dynamic Debug/Release triplet. Set `VCPKG_ROOT` to the vcpkg installation so both triplet folders can be searched. Set `buildRelease` to `false` to select Debug and Release host builds explicitly:

```matlab
% Build dynamic Debug and Release host libraries.
vcpkg.buildVcpkgDeps('path/to/manifest', ...
    'buildHostOnly', true, 'buildRelease', false)

% Build static Debug and Release host libraries.
vcpkg.buildVcpkgDeps('path/to/manifest', ...
    'buildHostOnly', true, 'buildDynamic', false, 'buildRelease', false)

% Query the static host triplet for Debug and Release builds.
vcpkg.getHostTriplet(false, false)
```

`x64-linux-release`, `x64-osx-release`, and `arm64-osx-release` build static dependency libraries with a dynamic C runtime (`VCPKG_CRT_LINKAGE`). Dependency library linkage is controlled separately by `VCPKG_LIBRARY_LINKAGE`; these triplets therefore apply to `buildDynamic=false`.

On MSVC, static Debug/Release builds use `x64-windows-static-md` when available, otherwise the built-in `x64-windows-static` triplet, which also uses a static C runtime.

The existing QNX and Speedgoat target overlays always build static Release-only libraries for either `buildRelease` value. No host overlay triplets are added by the toolbox.

### vcpkg diagnostics
Set `vcpkgDebug` to `true` to pass `--debug` to vcpkg and enable its diagnostic output. The default is `false`. Library build configuration is controlled separately by `buildRelease`.

```matlab
vcpkg.buildVcpkgDeps('path/to/manifest', 'vcpkgDebug', true)
```

The option previously named `debug` is now named `vcpkgDebug`; update existing calls accordingly.

## Testing
Open `VcpkgToolbox.prj` in MATLAB before running tests. `buildfile.m` is the entry point:

```matlab
buildtool unit                  % Unit tests; no vcpkg builds.
buildtool integration           % Host linkage and Release-only/Debug+Release modes.
buildtool integrationWithTarget % Static Release-only targets with all host modes.
buildtool test                  % Unit tests and host integration tests.
```

Integration tests require vcpkg and a supported compiler. Target integration tests also require an installed target support package and toolchain; they are skipped when no supported target is detected. Each build uses an isolated temporary manifest and installation folder. JUnit results are written under `results`.

For MATLAB releases without `buildtool`, run `runtests('tests', 'Tag', 'Unit')`. The unit tests use APIs available in R2020b.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)
