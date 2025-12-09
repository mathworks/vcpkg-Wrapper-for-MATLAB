function buildVcpkgDeps(manifestFolder, vpckgArguments, options)

% Copyright 2025 The MathWorks, Inc.

arguments
    manifestFolder {mustBeFolder}
    vpckgArguments {mustBeText} = {};
    options.buildHostOnly = false;
end

if ~iscellstr(vpckgArguments) && ~isstring(vpckgArguments)
    vpckgArguments = cellstr(vpckgArguments);
end

%% Prepare host
triplet = vcpkg.getHostTriplet;
hasMSVC = false;

if contains(triplet,'windows')
    hasMSVC = true;
    msvcSetupCmd = 'if not exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (echo vswhere.exe not found & exit /b 1) else for /f "usebackq tokens=*" %i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do call "%i\VC\Auxiliary\Build\vcvars64.bat"';
elseif ispc
    % Work with MinGW
    mingwRoot = getenv('MW_MINGW64_LOC');
    assert(isfolder(mingwRoot),'MinGW-w64 not found in MW_MINGW64_LOC. Please install the MATLAB support package for MinGW from the Add-On Manager.');

    % Add MinGW to system path
    addToSystemPath(fullfile(mingwRoot,'bin'));
end


%% Figure out target triplet

% Initialize variables
qnxSdpBat = '';

% Figure out target triplet if required
if options.buildHostOnly
    targetTriplet = '';
else
    targetTriplet = vcpkg.getTargetTriplet;

    if contains(targetTriplet, 'qnx', 'IgnoreCase', true)
        % Using QNX with Siumink Real-Time Target Support Package
        slrealtime.qnxSetupFcn;
        qnxSpRoot = getenv('SLREALTIME_QNX_SP_ROOT');
        qnxVersion = getenv('SLREALTIME_QNX_VERSION');

        if ispc
            qnxSdpBat = ['&& ',fullfile(qnxSpRoot,qnxVersion,'qnxsdp-env.bat')];
        elseif isunix
            % Sourcing the .sh file for qcc compilation.
            qnxSdpBat = ['&& ',append('source ',fullfile(qnxSpRoot,qnxVersion,'qnxsdp-env.sh'))];
        end
    end

    % Prepend --triplet argument if target triplet has an actual value
    if ~isempty(targetTriplet)
        targetTriplet = ['--triplet ', targetTriplet];
    end
end

%% Setup and run vcpkg

% Add vcpkg to path
addToSystemPath(getenv('VCPKG_ROOT'));

% Build up vcpkg full command
vcpkgCmd = ['cd ', manifestFolder, ' ',...
    qnxSdpBat,...
    ' && vcpkg install ',targetTriplet,' --host-triplet ', vcpkg.getHostTriplet,...
    ' --overlay-triplets "', fullfile(vcpkg.getToolboxRoot,'overlay-triplets'), '" ', strjoin(vpckgArguments,' ')];

if hasMSVC
    vcpkgCmd = [msvcSetupCmd, ' && ', vcpkgCmd];
end

% Run vcpkg command
status = system(vcpkgCmd, '-echo');
assert(status == 0, 'Error running vcpkg command');

end

function addToSystemPath(path)
oldPath = getenv("Path");
if ~contains(oldPath,path)
    setenv("Path",[path,';',oldPath]);
end
end