# vcpkg Wrapper for MATLAB&reg;

[![View vcpkg Wrapper for MATLAB on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/182780-vcpkg-wrapper-for-matlab)

This simple toolbox wraps [vcpkg - Open source C/C++ dependency manager from Microsoft&reg;](https://vcpkg.io/en/index.html) to ease the integration into MATLAB projects that use vcpkg [manifest mode](https://learn.microsoft.com/en-us/vcpkg/concepts/manifest-mode) to define its dependencies.
The wrapper toolbox figures out the host and target triplets as well as the compiler paths automatically. It only requires vcpkg to be available on the system's path.

## Setup
MATLAB Package Manager (MPM) is the primary installation mechanism for developers
using MATLAB R2024b or newer. The `.mltbx` installer remains available for end users
on MATLAB R2020b or newer. Both formats contain the same runtime code and Getting
Started guide.

### MPM installation (MATLAB R2024b+)

Install directly from a local clone, passing the **toolbox folder** as the package
root. Its definition is `toolbox/resources/mpackage.json`:

```matlab
pkg = mpminstall("C:/path/to/vcpkg-Wrapper-for-MATLAB/toolbox", Prompt=false);
mpmlist("vcpkgWrapper")
vcpkg.getToolboxRoot()
```

For an editable developer installation, keep the clone in a permanent location:

```matlab
pkg = mpminstall("C:/path/to/vcpkg-Wrapper-for-MATLAB/toolbox", ...
    Editable=true, InPlace=true, Prompt=false);
```

Alternatively, download `vcpkg-wrapper-toolbox-vX.Y.Z_mpm.zip` from
[GitHub Releases](https://github.com/mathworks/vcpkg-Wrapper-for-MATLAB/releases),
extract it, and install the extracted package folder:

```matlab
unzip("vcpkg-wrapper-toolbox-vX.Y.Z_mpm.zip", "vcpkg-wrapper-package");
pkg = mpminstall(fullfile(pwd, "vcpkg-wrapper-package"), Prompt=false);
```

The ZIP contains `resources/mpackage.json` at its package root; unzip it before
calling `mpminstall`. GitHub release assets are downloadable distribution files,
not an indexed MPM repository. Installing by the name `"vcpkgWrapper"` alone
requires publishing to a configured MPM repository.

### Toolbox installation (MATLAB R2020b+)

Download the `.mltbx` installer from GitHub Releases or
[File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/182780-vcpkg-wrapper-for-matlab)
and double-click it in MATLAB, or run:

```matlab
matlab.addons.toolbox.installToolbox("vcpkg-wrapper-toolbox-vX.Y.Z.mltbx");
vcpkg.getToolboxRoot()
```

Install one distribution of the wrapper in a MATLAB environment. The formats use
the existing toolbox UUID so they represent the same package. When switching
formats, remove the previous installation through its package manager first.
Both installers expose the runtime folder automatically. Opening `VcpkgToolbox.prj`
continues to configure the developer paths; no startup scripts are required.

### MathWorks Products (https://www.mathworks.com)
Requires MATLAB release R2020b or newer
- [MATLAB&reg;](https://www.mathworks.com/products/matlab.html)

### 3rd Party Products
- [vcpkg](https://github.com/microsoft/vcpkg)
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
buildtool packagingTest         % Verify MPM and toolbox artifacts (R2024b+).
```

Integration tests require vcpkg and a supported compiler. Target integration tests also require an installed target support package and toolchain; they are skipped when no supported target is detected. Each build uses an isolated temporary manifest and installation folder. JUnit results are written under `results`.

For MATLAB releases without `buildtool`, run `runtests('tests', 'Tag', 'Unit')`. The unit tests use APIs available in R2020b.

## Building and releasing

Build automation requires MATLAB R2024b or newer. Open `VcpkgToolbox.prj` and run:

```matlab
buildtool release              % Build both formats using the manifest version.
buildtool release('v1.2.3')     % Build both formats with one release version.
buildtool mpm('v1.2.3')         % Build only the MPM package ZIP.
buildtool package('v1.2.3')     % Existing toolbox-only command, unchanged.
```

The checks, runtime tests, and packaging tests run before packaging. Both outputs
remain in the repository root and are ignored by Git:

- `vcpkg-wrapper-toolbox-v1.2.3_mpm.zip`: the primary MPM folder distribution.
- `vcpkg-wrapper-toolbox-v1.2.3.mltbx`: the backward-compatible end-user installer.

`toolbox/resources/mpackage.json` is the single source for package identity,
version, summary, description, author, and minimum supported runtime release.
Its `0.0.0` development version preserves the old helper's default. A version
argument or GitHub release tag overrides that version only in the staged package;
the source manifest is unchanged. Tags must use numeric versions without
prerelease or build suffixes because `.mltbx` does not support those suffixes.
Set the manifest version when distributing an untagged source checkout as a release.

The legacy `packageToolbox(version)` helper still returns `ToolboxOptions` and
builds only the `.mltbx`, with its existing UUID and filename. The common
`packageVcpkg` helper supports both formats and an optional `OutputFolder`.
It stages the entire `toolbox` hierarchy under ignored `work`, validates the MPM
definition, and cleans the staging folder after packaging. Build helpers, tests,
CI files, and MATLAB project metadata are not shipped.

`main.yml` runs the default build tasks for cross-platform runtime and packaging
verification, retains the R2020b unit test job, and publishes test results.
On a `v*` tag, `release.yml` waits for CI, then explicitly runs the `release` task
on R2024b to generate both formats with that tag's version. It prunes checks
already completed by CI, archives both artifacts, and publishes them as GitHub
release assets. Neither workflow publishes to an MPM repository or File Exchange.

Runtime compatibility remains R2020b+, while MPM installation and artifact
authoring require R2024b+. The existing desktop Windows, Linux, and macOS support
is retained; MATLAB Online is not supported because the wrapper needs external
tools. The legacy `.prj` format remains supported across these releases.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)
