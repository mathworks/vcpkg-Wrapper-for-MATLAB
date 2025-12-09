function triplet = getTargetTriplet

% Copyright 2025 The MathWorks, Inc.

triplet = '';

if isMATLABReleaseOlderThan('R2026a') && ~isMATLABReleaseOlderThan('R2020b')
    try
        slrealtime.qnxSetupFcn;
        triplet = 'x64-qnx-static';
    catch
        % SLRT is not installed. Don't build for any target
    end
elseif isMATLABReleaseOlderThan('R2020b')
    triplet = 'x86-windows-static';
else
    error('Target triplet is not supported for MATLAB R2026a and later yet. Use buildHostOnly.');
end

end