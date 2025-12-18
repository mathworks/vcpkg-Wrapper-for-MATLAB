function triplet = getTargetTriplet

% Copyright 2025 The MathWorks, Inc.

triplet = '';

if isMATLABReleaseOlderThan('R2026a') && ~isMATLABReleaseOlderThan('R2020b')
    spkgInfo = matlabshared.supportpkg.getInstalled;
    if any(contains({spkgInfo.Name}, 'Simulink Real-Time Target Support Package'))
        triplet = 'x64-qnx-static';
    end
elseif isMATLABReleaseOlderThan('R2020b')
    triplet = 'x86-windows-static';
else
    error('Target triplet is not supported for MATLAB R2026a and later yet. Use buildHostOnly.');
end

end