function triplet = getHostTriplet
%getHostTriplet Return the vcpkg triplet for the selected MATLAB C++ compiler.
%   TRIPLET = vcpkg.getHostTriplet returns the vcpkg host triplet that
%   matches the current platform and the selected MATLAB C++ MEX compiler.
%   On Windows, MSVC and MinGW are distinguished from the selected compiler.

% Copyright 2025 The MathWorks, Inc.

cfg = mex.getCompilerConfigurations('C++', 'Selected');

if isempty(cfg)
    error('vcpkg:getHostTriplet:CompilerNotFound', ...
        ['No compiler was found for this MATLAB installation. Please run ', ...
        '"mex -setup" on the MATLAB command window first, and install a ', ...
        'supported C/C++ compiler.']);
end

if ispc
    if contains(cfg.ShortName, 'MSVC', 'IgnoreCase', true)
        triplet = 'x64-windows-static-md';
    elseif contains(cfg.ShortName, 'mingw', 'IgnoreCase', true)
        triplet = 'x64-mingw-static';
    else
        error('vcpkg:getHostTriplet:UnsupportedCompiler', ...
            'Compiler %s not supported.', cfg.Name);
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

end