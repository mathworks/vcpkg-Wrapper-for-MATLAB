function triplet = getHostTriplet

% Copyright 2025 The MathWorks, Inc.

cfg = mex.getCompilerConfigurations('C++', 'Selected');

if ispc
    if contains(cfg.ShortName,'MSVC','IgnoreCase',true)
        triplet = 'x64-windows-static-md';
    elseif contains(cfg.ShortName,'mingw','IgnoreCase',true)
        triplet = 'x64-mingw-static';
    else
        error('Compiler %s not supported', cfg.Name);
    end
elseif isunix && ~ismac
    triplet = 'x64-linux';
elseif ismac
    triplet = 'x64-osx';
else
    error('Platform not supported');
end

end

