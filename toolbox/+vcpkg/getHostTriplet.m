function triplet = getHostTriplet(buildDynamic, buildRelease)
%getHostTriplet - Return the vcpkg triplet for the selected C++ compiler
%   TRIPLET = getHostTriplet returns the dynamic host triplet matching
%   the current platform and selected MATLAB C++ MEX compiler. It prefers
%   a Release-only triplet from vcpkg's built-in or community folders.
%   On Windows, the selected compiler distinguishes MSVC from MinGW.
%
%   TRIPLET = getHostTriplet(buildDynamic) selects dynamic libraries when
%   buildDynamic is true (default), or static libraries when false.
%   buildDynamic must be scalar and is converted to logical.
%
%   TRIPLET = getHostTriplet(buildDynamic, buildRelease) selects a
%   Release-only triplet when buildRelease is true (default). When false,
%   the triplet builds both Debug and Release libraries. buildRelease
%   must be scalar and is converted to logical.
%   If a dynamic Release-only triplet is unavailable under VCPKG_ROOT,
%   a warning is issued and the dynamic Debug/Release triplet is used.
%
%   See also buildVcpkgDeps, getTargetTriplet

% Copyright 2025 The MathWorks, Inc.

arguments
    buildDynamic (1,1) logical = true;
    buildRelease (1,1) logical = true;
end

if ispc
    compilerConfiguration = mex.getCompilerConfigurations('C++', 'Selected');

    if isempty(compilerConfiguration) && isfolder(getenv('MW_MINGW64_LOC'))
        triplet = 'x64-mingw';
    elseif isempty(compilerConfiguration)
        error('vcpkg:getHostTriplet:CompilerNotFound', ...
            ['No compiler was found for this MATLAB installation. Please run ', ...
            '"mex -setup" on the MATLAB command window first, and install a ', ...
            'supported C/C++ compiler.']);
    elseif contains(compilerConfiguration.ShortName, 'MSVC', 'IgnoreCase', true)
        triplet = 'x64-windows';
    elseif contains(compilerConfiguration.ShortName, 'mingw', 'IgnoreCase', true)
        triplet = 'x64-mingw';
    else
        error('vcpkg:getHostTriplet:UnsupportedCompiler', ...
            'Compiler %s not supported.', compilerConfiguration.Name);
    end
elseif isunix && ~ismac
    triplet = 'x64-linux';
elseif ismac
    if strcmp(computer('arch'), 'maca64')
        triplet = 'arm64-osx';
    else
        triplet = 'x64-osx';
    end
else
    error('vcpkg:getHostTriplet:UnsupportedPlatform', 'Platform not supported.');
end

if contains(triplet, 'windows')
    if ~buildDynamic
        triplet = [triplet, '-static-md'];
    end
elseif contains(triplet, 'mingw')
    if buildDynamic
        triplet = [triplet, '-dynamic'];
    else
        triplet = [triplet, '-static'];
    end
elseif buildDynamic
    % Linux and macOS triplets without a suffix use static libraries
    triplet = [triplet, '-dynamic'];
end

if buildRelease
    releaseTriplet = [triplet, '-release'];
    tripletRoot = fullfile(getenv('VCPKG_ROOT'), 'triplets');
    hasReleaseTriplet = isfile(fullfile(tripletRoot, [releaseTriplet, '.cmake'])) || ...
        isfile(fullfile(tripletRoot, 'community', [releaseTriplet, '.cmake']));
    if buildDynamic && ~contains(triplet, 'mingw') && ~hasReleaseTriplet
        warning('vcpkg:getHostTriplet:ReleaseTripletUnavailable', ...
            ['Release-only triplet %s was not found in VCPKG_ROOT/triplets ', ...
            'or its community folder. Using %s for dynamic Debug and Release ', ...
            'libraries. Set buildRelease to false to select this explicitly.'], ...
            releaseTriplet, triplet);
    else
        triplet = releaseTriplet;
    end
elseif strcmp(triplet, 'x64-windows-static-md')
    tripletRoot = fullfile(getenv('VCPKG_ROOT'), 'triplets');
    hasStaticMdTriplet = isfile(fullfile(tripletRoot, [triplet, '.cmake'])) || ...
        isfile(fullfile(tripletRoot, 'community', [triplet, '.cmake']));
    if ~hasStaticMdTriplet
        triplet = 'x64-windows-static';
    end
end

end
