function triplet = getTargetTriplet
%getTargetTriplet Return the default vcpkg target triplet for this MATLAB setup.
%   TRIPLET = vcpkg.getTargetTriplet returns the target triplet implied by
%   the installed target support package and MATLAB release. If no supported
%   target environment is detected, TRIPLET is empty.

% Copyright 2025 The MathWorks, Inc.

triplet = '';

installedProducts = ver;
installedProductNames = {installedProducts.Name}';

if any(contains(installedProductNames, 'Simulink Real-Time'))
    if isMATLABReleaseOlderThan('R2026a') && ~isMATLABReleaseOlderThan('R2020b')
        triplet = 'x64-qnx-static';
    elseif isMATLABReleaseOlderThan('R2020b')
        triplet = 'x86-windows-static';
    else
        triplet = 'x64-speedgoat-linux-static';
    end
end

end