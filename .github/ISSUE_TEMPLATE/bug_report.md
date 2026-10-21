---
name: MATLAB toolbox bug report
about: Report an installation, configuration, or dependency-build problem with vcpkg Wrapper for MATLAB
title: ''
labels: bug
assignees: ''

---

<!-- Replace the prompts with your details. Omit fields that do not apply.
Use a small reproduction and remove private information from code and logs. -->

## Problem

Describe what failed and whether the problem occurs consistently.

## Environment

- MATLAB release and update:
- Operating system and version:
- Processor architecture:
- Wrapper version or source commit:
- Installation method: MPM, `.mltbx`, or source clone with `VcpkgToolbox.prj` open:

For dependency-build problems, also include:

- vcpkg version or source commit:
- Selected C/C++ compiler and version:
- Build scope: host only, or host and embedded target:
- Embedded target, support package, and toolchain versions, if applicable:
- Build options: `buildHostOnly`, `buildDynamic`, `buildRelease`, and any extra vcpkg arguments:
- Selected host and target triplets, if available in the build output:

These commands can help collect environment details. Run the wrapper commands
only if the toolbox is installed and accessible:

```matlab
version
computer
which vcpkg.buildVcpkgDeps -all
vcpkg.getToolboxRoot()
getenv('VCPKG_ROOT')
mex.getCompilerConfigurations('C++', 'Selected')
```

## Minimal reproduction

List the setup steps and provide the exact MATLAB commands that reproduce the
problem. For installation failures, include the installation command or steps.

```matlab
% Paste a minimal reproduction here, including the options used.
```

For dependency-build failures, include a minimal `vcpkg.json` and any custom
triplet or overlay files required to reproduce the problem.

```json
```

## Expected and actual behavior

Describe the expected result and what happened instead.

## Error messages and build output

Paste the full MATLAB error message, error identifier, and stack trace as text.
For dependency-build failures, include the relevant vcpkg output and build-log
excerpt. If you can repeat the failing call, enable `vcpkgDebug=true` to collect
additional diagnostics.

```text
```

## Additional context

If applicable, include the last working wrapper or MATLAB version, recent
environment changes, and any workaround you have tried. Attach screenshots
only when they help explain a visual problem.
