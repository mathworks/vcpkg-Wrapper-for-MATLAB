function triplet = getHostTriplet(buildDynamic)
%getHostTriplet - Return the vcpkg triplet for the selected C++ compiler
%   TRIPLET = getHostTriplet returns the dynamic vcpkg host triplet that
%   matches the current platform and selected MATLAB C++ MEX compiler.
%   On Windows, the selected compiler distinguishes MSVC from MinGW.
%
%   TRIPLET = getHostTriplet(buildDynamic) selects dynamic libraries when
%   buildDynamic is true (default), or static libraries when false.
%   buildDynamic must be a scalar logical value.
%
%   See also buildVcpkgDeps, getTargetTriplet

% Copyright 2025 The MathWorks, Inc.

arguments
    buildDynamic (1,1) {mustBeA(buildDynamic, 'logical')} = true;
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

end
