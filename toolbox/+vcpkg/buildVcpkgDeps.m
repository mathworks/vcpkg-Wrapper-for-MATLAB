function dependencyPaths = buildVcpkgDeps(manifestFolder, vpckgArguments, options)
%buildVcpkgDeps - Build vcpkg manifest dependencies for the host and target
%   buildVcpkgDeps(manifestFolder) builds dependencies from the manifest
%   in manifestFolder. Host libraries are dynamic and prefer Release-only
%   triplets by default. Embedded targets always use static Release-only
%   libraries. If no supported target is detected, dependencies are built
%   for the host.
%
%   buildVcpkgDeps(manifestFolder, vpckgArguments) also passes additional
%   vcpkg install arguments as text or an array of text values.
%
%   buildVcpkgDeps(..., buildDynamic=TF) selects dynamic host libraries
%   when TF is true (default), or static host libraries when TF is false.
%   TF must be scalar and is converted to logical. Targets remain static.
%
%   buildVcpkgDeps(..., buildRelease=TF) selects Release-only host builds
%   when TF is true (default), or both Debug and Release when false.
%   TF is scalar and converted to logical. Targets stay Release-only.
%   If a dynamic Release-only triplet is unavailable, a warning is issued
%   and the dynamic Debug/Release triplet is used.
%
%   buildVcpkgDeps(..., buildHostOnly=TF) builds only host dependencies
%   when TF is true. The default is false.
%
%   buildVcpkgDeps(..., vcpkgDebug=TF) enables vcpkg diagnostic output
%   with the --debug flag when TF is true. The default is false. Library
%   build configuration is selected separately with buildRelease.
%
%   buildVcpkgDeps(...) automatically maps Windows QNX dependency folders
%   containing whitespace to temporary drive letters while building. The
%   libraries remain in the original vcpkg folders, and the mappings are
%   removed on completion or error. Each affected root requires an unused
%   drive letter. Forwarded root arguments can still select other folders.
%
%   dependencyPaths = buildVcpkgDeps(...) returns a structure containing
%   installRoot, buildtreesRoot, packagesRoot, hostDir, and targetDir as
%   absolute character vectors. Use hostDir and targetDir to configure
%   consumers when dependencies are installed outside the manifest folder.
%   These paths refer to the physical folders, not temporary drive letters.
%
%   See also getHostTriplet, getTargetTriplet

% Copyright 2025 The MathWorks, Inc.

arguments
    manifestFolder char {mustBeFolder}
    vpckgArguments {mustBeText} = {};
    options.buildDynamic (1,1) logical = true;
    options.buildRelease (1,1) logical = true;
    options.buildHostOnly (1,1) logical = false;
    options.vcpkgDebug (1,1) logical = false;
end

if ~iscellstr(vpckgArguments) && ~isstring(vpckgArguments)
    vpckgArguments = cellstr(vpckgArguments);
end

dependencyPaths = resolveDependencyPaths(manifestFolder, vpckgArguments);
rootArguments = '';

experimentalArguments = unique(regexp(char(strjoin(vpckgArguments, ' ')), ...
    '(?<!\S)--x-(?:install|manifest|packages)-root(?==|\s|$)', ...
    'match'), 'stable');
if ~isempty(experimentalArguments)
    warning('vcpkg:buildVcpkgDeps:ExperimentalArgument', ...
        'The following arguments use experimental vcpkg features: %s.', ...
        strjoin(experimentalArguments, ', '));
end


%% Prepare host
triplet = vcpkg.getHostTriplet(options.buildDynamic, options.buildRelease);
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
targetEnvRootBat = '';

% Figure out target triplet if required
if options.buildHostOnly
    targetTriplet = triplet;
else
    targetTriplet = vcpkg.getTargetTriplet;
    if isempty(targetTriplet)
        targetTriplet = triplet;
    end

    if contains(targetTriplet, 'qnx', 'IgnoreCase', true)
        % Using QNX with Simulink Real-Time Target Support Package
        slrealtime.qnxSetupFcn;
        qnxSpRoot = getenv('SLREALTIME_QNX_SP_ROOT');
        qnxVersion = getenv('SLREALTIME_QNX_VERSION');

        if ispc
            targetEnvRootBat = ['&& call "',fullfile(qnxSpRoot,qnxVersion,'qnxsdp-env.bat'),'"'];
        elseif isunix
            % Sourcing the .sh file for qcc compilation.
            targetEnvRootBat = ['&& source "',fullfile(qnxSpRoot,qnxVersion,'qnxsdp-env.sh'),'"'];
        end
    elseif contains(targetTriplet, 'speedgoat-linux', 'IgnoreCase', true)
        if contains(targetTriplet, 'x64', 'IgnoreCase', true)
            arch = 'x64';
        elseif contains(targetTriplet, 'arm64', 'IgnoreCase', true)
            arch = 'aarch64';
        end

        % Get Speedgoat I/O Blockset paths
        if isMATLABReleaseOlderThan('R2026b')
            sgHWConfigObj = slrealtime.internal.HardwareConfig.getHWConfigObject();
        else
            [sgHWConfigObj, ~] = slrealtime.internal.HardwareConfig.getHWConfigObjectByName('Speedgoat I/O Blockset');
        end
        hasSpeedgoatPath = ~isempty(sgHWConfigObj);

        % Error out if no compilation path is available
        if ~hasSpeedgoatPath
            error(message('slrealtime:hwconfig:noAddOnsInstalled'));
        end

        % Yocto cc specific implementation
        try
            CCPath = sgHWConfigObj.getToolchainPath(arch);
        catch ME
            error(message('slrealtime:utils:toolChainError', ME.message));
        end

        if isempty(CCPath)
            if strcmp(arch,'x64')
                error(message('slrealtime:utils:x64CCRootNotSet'));
            elseif strcmp(arch,'aarch64')
                error(message('slrealtime:utils:armCCRootNotSet'));
            else
                error('Compiler toolchain root not set.');
            end
        end

        if ispc
            targetEnvRootBat = ['&& ',fullfile(CCPath,sprintf('%scc-setup-env.bat',arch))];
        elseif isunix && ~ismac
            targetEnvRootBat = ['&& ',append('source ',fullfile(CCPath,sprintf('%scc-setup-env.sh',arch)))];
        else
            error('Current host OS is still not supported.');
        end
    end
end

dependencyPaths.hostDir = fullfile(dependencyPaths.installRoot, triplet);
dependencyPaths.targetDir = fullfile(dependencyPaths.installRoot, targetTriplet);

if ispc && contains(targetTriplet, 'qnx', 'IgnoreCase', true)
    [vpckgArguments, rootArguments, mappingCleanup] = ...
        mapQnxDependencyPaths(dependencyPaths, vpckgArguments); %#ok<ASGLU>
end

%% Setup and run vcpkg

% Add vcpkg to path
addToSystemPath(getenv('VCPKG_ROOT'));

% Enable vcpkg diagnostics
if options.vcpkgDebug
    vcpkgDebugArg = ' --debug ';
else
    vcpkgDebugArg = '';
end

% Build up vcpkg full command
if ispc
    changeFolderCmd = ['cd /d "', manifestFolder, '"'];
else
    changeFolderCmd = ['cd "', manifestFolder, '"'];
end
vcpkgCmd = [changeFolderCmd, ' ',...
    targetEnvRootBat,...
    ' && vcpkg install --triplet ',targetTriplet,' --host-triplet ', triplet,...
    ' --overlay-triplets "', fullfile(vcpkg.getToolboxRoot,'overlay-triplets'), '" ', ...
    strjoin(vpckgArguments,' '), ' ', rootArguments, vcpkgDebugArg];

if hasMSVC
    vcpkgCmd = [msvcSetupCmd, ' && ', vcpkgCmd];
end

% Run vcpkg command
if isunix && ~ismac
    % Use system libraries in the child process instead of MATLAB libraries.
    % SDK setup in vcpkgCmd can still establish its own library paths.
    status = system(vcpkgCmd, '-echo', 'LD_LIBRARY_PATH', missing);
else
    status = system(vcpkgCmd, '-echo');
end
if status ~= 0
    error('vcpkg:buildVcpkgDeps:CommandFailed', ...
        'Error running vcpkg command (exit status %d).', status);
end

end

function paths = resolveDependencyPaths(manifestFolder, arguments)
manifestFolder = absoluteFolder(manifestFolder, pwd);
vcpkgRoot = absoluteFolder(getenv('VCPKG_ROOT'), pwd);
paths = struct('installRoot', fullfile(manifestFolder, 'vcpkg_installed'), ...
    'buildtreesRoot', fullfile(vcpkgRoot, 'buildtrees'), ...
    'packagesRoot', fullfile(vcpkgRoot, 'packages'));
forwarded = char(strjoin(arguments, ' '));
names = {'install', 'buildtrees', 'packages'};
for index = 1:numel(names)
    pattern = ['(?<!\S)--(?:x-)?', names{index}, ...
        '-root(?:=|\s+)(?<root>"[^"]*"|''[^'']*''|\S+)'];
    tokens = regexp(forwarded, pattern, 'names');
    if ~isempty(tokens)
        if numel(tokens) > 1
            error('vcpkg:buildVcpkgDeps:ConflictingRootArguments', ...
                'Specify the %s root only once.', names{index});
        end
        root = tokens.root;
        if startsWith(root, '"') || startsWith(root, '''')
            root = root(2:end-1);
        end
        paths.([names{index}, 'Root']) = absoluteFolder(root, manifestFolder);
    end
end
end

function [arguments, rootArguments, cleanup] = mapQnxDependencyPaths(paths, arguments)
names = {'install', 'buildtrees', 'packages'};
cleanups = {};
rootArguments = '';
forwarded = char(strjoin(arguments, ' '));
for index = 1:numel(names)
    root = paths.([names{index}, 'Root']);
    if isempty(regexp(root, '\s', 'once'))
        continue
    end
    if ~isfolder(root)
        [success, message] = mkdir(root);
        if ~success
            error('vcpkg:buildVcpkgDeps:CannotCreateRoot', '%s', message);
        end
    end
    drive = createDriveMapping(root);
    cleanups{end+1} = onCleanup(@() removeDriveMapping(drive, root)); %#ok<AGROW>
    pattern = ['(?<!\S)--(?:x-)?', names{index}, ...
        '-root(?:=|\s+)(?:"[^"]*"|''[^'']*''|\S+)'];
    forwarded = regexprep(forwarded, pattern, '');
    rootArguments = [rootArguments, sprintf(' --x-%s-root="%s/"', names{index}, drive)]; %#ok<AGROW>
end
arguments = {forwarded};
% Transfer ownership without running the local cleanup objects prematurely.
cleanup = cleanups;
end

function drive = createDriveMapping(root)
% SUBST refuses occupied letters; it does not replace an existing mapping.
for letter = 'Z':-1:'D'
    drive = [letter, ':'];
    [status, ~] = system(sprintf('subst %s "%s"', drive, root));
    if status == 0
        return
    end
end
error('vcpkg:buildVcpkgDeps:DriveMappingFailed', ...
    ['Cannot create a temporary drive mapping for QNX dependency folder %s. ', ...
    'An unused drive letter and permission to run SUBST are required.'], root);
end

function removeDriveMapping(drive, root)
% Remove only the mapping this invocation owns.
[status, mappings] = system('subst');
expected = [drive, '\: => ', root];
if status == 0 && any(strcmpi(strtrim(splitlines(string(mappings))), expected))
    [status, output] = system(['subst ', drive, ' /D']);
    if status ~= 0
        warning('vcpkg:buildVcpkgDeps:DriveMappingCleanupFailed', ...
            'Cannot remove temporary drive %s: %s', drive, strtrim(output));
    end
end
end

function folder = absoluteFolder(folder, baseFolder)
if ispc
    isAbsolute = ~isempty(regexp(folder, '^(?:[A-Za-z]:[\\/]|[\\/]{2})', 'once'));
else
    isAbsolute = startsWith(folder, '/');
end
if ~isAbsolute
    folder = fullfile(baseFolder, folder);
end
[exists, attributes] = fileattrib(folder);
if exists
    folder = attributes.Name;
else
    [parent, name, extension] = fileparts(folder);
    folder = fullfile(absoluteFolder(parent, baseFolder), [name, extension]);
end
end

function addToSystemPath(path)
oldPath = getenv("Path");
if ~contains(oldPath,path)
    setenv("Path",[path,';',oldPath]);
end
end
