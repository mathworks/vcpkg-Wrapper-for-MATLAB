# MATLAB toolbox development

## Testing
Open `VcpkgToolbox.prj` in MATLAB before running tests. `buildfile.m` is the entry point:

```matlab
buildtool unit                  % Unit tests; no vcpkg builds.
buildtool integration           % Host linkage and Release-only/Debug+Release modes.
buildtool integrationWithTarget % Static Release-only targets with all host modes.
buildtool test                  % Unit tests and host integration tests.
buildtool packagingTest         % Verify toolbox and embedded metadata (R2024b+).
```

Integration tests require vcpkg and a supported compiler. Target integration tests also require an installed target support package and toolchain; they are skipped when no supported target is detected. Each build uses an isolated temporary manifest and installation folder. JUnit results are written under `results`.

For MATLAB releases older than R2024b, open the project and run `runtests('tests', 'Tag', 'Unit')` directly. The build file requires R2024b or newer; the unit tests use APIs available in R2020b.

## Building and releasing

Build automation requires MATLAB R2024b or newer. Open `VcpkgToolbox.prj` and run:

```matlab
buildtool release                 % Build using the manifest version locally.
buildtool("release('v1.2.3')")     % Build with an explicit release version.
```

The checks, runtime tests, and packaging tests run before packaging. The installer
is saved as `release/vcpkgWrapper-1.2.3.mltbx` for version `1.2.3` in the ignored
`release/` folder. With the current development manifest and no version override,
the filename is `release/vcpkgWrapper-0.0.0.mltbx`.

`toolbox/resources/mpackage.json` is the single source for package identity,
version, summary, toolbox description, author, and minimum supported runtime release.
The embedded MPM documentation comes from the root `README.md`, which is copied
into the toolbox. Builds on R2026b or newer use the `readme` field in schema
1.2.0; earlier releases embed the full README text in the `description` field.
Its `0.0.0` development version is the default for local builds. A version
argument or GitHub release tag overrides that version only in the staged package;
the source manifest is unchanged. Tags must use numeric versions without
prerelease or build suffixes because `.mltbx` does not support those suffixes.
Set the manifest version when distributing an untagged source checkout as a release.

The `release` build task calls `packageVcpkg` to build the `.mltbx`
with the manifest UUID and filename convention `vcpkgWrapper-X.Y.Z.mltbx`.
The helper defaults to `release/` and accepts an optional `OutputFolder` override.
It stages the entire `toolbox` hierarchy under ignored `work`, validates the MPM
definition, and cleans the staging folder after packaging. Build helpers, tests,
CI files, and MATLAB project metadata are not shipped.

`main.yml` runs the default build tasks for cross-platform runtime and packaging
verification, retains the R2020b unit test job, and publishes test results.
On a `v*` tag, `release.yml` waits for CI, then explicitly runs the `release` task
using the default MATLAB release to generate the `.mltbx` with that tag's version.
It prunes checks already completed by CI, and publishes the installer
as a GitHub release asset. Neither workflow publishes to an MPM repository or
File Exchange.

Runtime compatibility and standard `.mltbx` installation remain R2020b+.
MPM installation requires R2026b+, while artifact authoring requires R2024b+.
The existing desktop Windows, Linux, and macOS support is retained; MATLAB
Online is not supported because the wrapper needs external tools. The legacy
`.prj` format remains supported across these releases.
