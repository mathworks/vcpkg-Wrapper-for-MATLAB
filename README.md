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
Host libraries are built dynamically by default. Set the optional scalar logical argument `buildDynamic` to `false` to build static host libraries. Supported embedded target builds always use static libraries, regardless of this option.

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

`vcpkg.getHostTriplet()` returns the dynamic host triplet; `vcpkg.getHostTriplet(false)` returns the static host triplet:

| Host/compiler | Dynamic (default) | Static |
| --- | --- | --- |
| Windows / MSVC | `x64-windows` | `x64-windows-static-md` |
| Windows / MinGW | `x64-mingw-dynamic` | `x64-mingw-static` |
| Linux | `x64-linux-dynamic` | `x64-linux` |
| macOS / Intel | `x64-osx-dynamic` | `x64-osx` |
| macOS / Apple silicon | `arm64-osx-dynamic` | `arm64-osx` |

Applications using dynamic libraries must make the corresponding shared libraries available at runtime.

## Testing
Open `VcpkgToolbox.prj` in MATLAB before running tests. `buildfile.m` is the entry point:

```matlab
buildtool unit                  % Unit tests; no vcpkg builds.
buildtool integration           % Dynamic and static host builds of fmt.
buildtool integrationWithTarget % Static target builds with both host linkage modes.
buildtool test                  % Unit tests and host integration tests.
```

Integration tests require vcpkg and a supported compiler. Target integration tests also require an installed target support package and toolchain; they are skipped when no supported target is detected. Each build uses an isolated temporary manifest and installation folder. JUnit results are written under `results`.

For MATLAB releases without `buildtool`, run `runtests('tests', 'Tag', 'Unit')`. The unit tests use APIs available in R2020b.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)
