function triplet = getTargetTriplet

% Copyright 2025 The MathWorks, Inc.

% Initialize target triplet
triplet = '';

% Get simple list of installed toolboxes
listToolbox = ver;
listToolbox = {listToolbox.Name}';

% Figure out target triplet based on installed target toolbox
if any(contains(listToolbox,'Simulink Real-Time'))
    if isMATLABReleaseOlderThan('R2026a') && ~isMATLABReleaseOlderThan('R2020b')
        triplet = 'x64-qnx-static';
    elseif isMATLABReleaseOlderThan('R2020b')
        triplet = 'x86-windows-static';
    else
        % MATLAB R2026a or later
        triplet = 'x64-speedgoat-linux-static';
    end
end

end