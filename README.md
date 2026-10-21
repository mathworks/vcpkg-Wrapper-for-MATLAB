# vcpkg Wrapper for MATLAB&reg;

[![View vcpkg Wrapper for MATLAB on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/182780-vcpkg-wrapper-for-matlab)

This toolbox wraps [vcpkg - Open source C/C++ dependency manager from Microsoft&reg;](https://vcpkg.io/en/index.html) for MATLAB projects that use vcpkg [manifest mode](https://learn.microsoft.com/en-us/vcpkg/concepts/manifest-mode) to define their C/C++ dependencies.
The wrapper selects host and target triplets and configures compiler paths automatically. Install vcpkg and a supported compiler, and set `VCPKG_ROOT` to the vcpkg installation folder. The wrapper adds that folder to the system path when building dependencies.

## Setup
Use MATLAB Package Manager (MPM) only in MATLAB R2026b or newer. For MATLAB
R2020b through R2026a, use the standard `.mltbx` toolbox installation described
below. Releases distribute a single `.mltbx` installer for MATLAB R2020b or
newer, including the MPM package definition, runtime code, and Getting Started
guide.

### MPM installation (MATLAB R2026b+)

With an internet connection and access to the File Exchange repository, install
the package from MATLAB:

```matlab
mpminstall vcpkgWrapper
```

For an editable developer installation, keep the clone in a permanent location
and pass the **toolbox folder** as the package root. Its definition is
`toolbox/resources/mpackage.json`:

```matlab
pkg = mpminstall("C:/path/to/vcpkg-Wrapper-for-MATLAB/toolbox", ...
    Editable=true, InPlace=true, Prompt=false);
```

### Toolbox installation (MATLAB R2020b+)

The `.mltbx` method is preferred for offline computers and is also supported in
MATLAB R2020b or newer.

Download the `.mltbx` installer from
[GitHub Releases](https://github.com/mathworks/vcpkg-Wrapper-for-MATLAB/releases) or
[File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/182780-vcpkg-wrapper-for-matlab).
For an offline computer, download it on a computer with internet access and
transfer the installer to the offline computer. Double-click it in MATLAB, or run:

```matlab
matlab.addons.toolbox.installToolbox("vcpkgWrapper-X.Y.Z.mltbx");
vcpkg.getToolboxRoot()
```

Replace `X.Y.Z` with the downloaded release version. For example, tag `v1.2.3`
produces `vcpkgWrapper-1.2.3.mltbx`.

Install the wrapper once in a MATLAB environment. MPM and the toolbox installer
use the same package UUID. When switching installation methods, remove the
previous installation through its package manager first.
Both methods expose the runtime folder automatically. For development from a
clone, opening `VcpkgToolbox.prj` configures the source, helper, and test paths;
no startup scripts are required.

### MathWorks Products (https://www.mathworks.com)
Requires MATLAB release R2020b or newer

- [MATLAB&reg;](https://www.mathworks.com/products/matlab.html)

### 3rd Party Products

- [vcpkg](https://github.com/microsoft/vcpkg); set `VCPKG_ROOT` to its installation folder.
- A supported C/C++ compiler; configure it with `mex -setup C++`.

The MPM definition explicitly declares `"dependencies": []`: the wrapper does
not require any other MATLAB packages. MATLAB itself is covered by the release
compatibility constraint. External vcpkg and the compiler must be installed
separately; MPM does not install them. Simulink Real-Time and its target support
packages/toolchains are optional, required only for the corresponding embedded
target builds. C/C++ libraries in a consumer's `vcpkg.json` (and the `fmt` sample
under `tests`) are managed by vcpkg, not by the wrapper's MPM dependency list.

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

`vcpkg.getHostTriplet()` selects dynamic host libraries with a preference for Release-only builds; `vcpkg.getHostTriplet(false)` selects static Release-only host libraries. With the default `buildRelease=true`, the host triplets are:

| Host/compiler | Dynamic (default) | Static |
| --- | --- | --- |
| Windows / MSVC | `x64-windows-release` if available, otherwise `x64-windows` | `x64-windows-static-md-release` |
| Windows / MinGW | `x64-mingw-dynamic-release` | `x64-mingw-static-release` |
| Linux | `x64-linux-dynamic-release` if available, otherwise `x64-linux-dynamic` | `x64-linux-release` |
| macOS / Intel | `x64-osx-dynamic-release` if available, otherwise `x64-osx-dynamic` | `x64-osx-release` |
| macOS / Apple silicon | `arm64-osx-dynamic-release` if available, otherwise `arm64-osx-dynamic` | `arm64-osx-release` |

Host triplets must be available in the installed vcpkg's `triplets` or
`triplets/community` folder. Static Release-only and MinGW Release-only builds
require the corresponding `-release` triplet; they have no fallback.

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

The existing embedded target overlays always build static Release-only libraries for either `buildRelease` value. No host overlay triplets are added by the toolbox.

### vcpkg diagnostics
Set `vcpkgDebug` to `true` to pass `--debug` to vcpkg and enable its diagnostic output. The default is `false`. Library build configuration is controlled separately by `buildRelease`.

```matlab
vcpkg.buildVcpkgDeps('path/to/manifest', 'vcpkgDebug', true)
```

The option previously named `debug` is now named `vcpkgDebug`; update existing calls accordingly.

## For MATLAB toolbox developers

See the [development guide](https://github.com/mathworks/vcpkg-Wrapper-for-MATLAB/blob/main/DEVELOPMENT.md) for testing, building, and releasing the toolbox.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)
