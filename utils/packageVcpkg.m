function [artifacts, toolboxOptions] = packageVcpkg(rootFolder, version, options)
%packageVcpkg - Build MPM and toolbox artifacts from shared metadata
%   ARTIFACTS = packageVcpkg(rootFolder) builds an MPM folder ZIP and a
%   toolbox installer in rootFolder using toolbox/resources/mpackage.json.
%
%   [...] = packageVcpkg(rootFolder,VERSION) also specifies release
%   version text, a leading-v tag, or a scalar matlab.mpm.Version object.
%
%   [...] = packageVcpkg(...,Formats=FORMATS) selects "mpm", "toolbox",
%   or both. The default builds both formats.
%
%   [...] = packageVcpkg(...,OutputFolder=FOLDER) changes the destination.
%
%   [ARTIFACTS,toolboxOptions] = packageVcpkg(...) also returns the
%   ToolboxOptions used for the installer, or [] for an MPM-only build.
%
%   See also packageToolbox, readVcpkgPackage, matlab.mpm.Package

arguments
    rootFolder {mustBeTextScalar}
    version = ""
    options.Formats (1,:) string {mustBeNonempty, ...
        mustBeMember(options.Formats, ["mpm", "toolbox"])} = ["mpm", "toolbox"]
    options.OutputFolder {mustBeTextScalar} = rootFolder
end

[metadata, version] = readVcpkgPackage(rootFolder, version);
versionText = string(version);
artifactBase = "vcpkg-wrapper-toolbox-v" + versionText;
workFolder = fullfile(rootFolder, "work");
if ~isfolder(workFolder)
    mkdir(workFolder);
end
stagingFolder = string(tempname(workFolder));
mkdir(stagingFolder);
cleanup = onCleanup(@() rmdir(stagingFolder, 's'));
toolboxFolder = fullfile(stagingFolder, "toolbox");
copyfile(fullfile(rootFolder, "toolbox"), toolboxFolder);
writelines(jsonencode(metadata, PrettyPrint=true), ...
    fullfile(toolboxFolder, "resources", "mpackage.json"), Encoding="UTF-8");

% Validate the staged definition without changing the installed environment.
pkg = matlab.mpm.Package(toolboxFolder);
assert(pkg.Version == version, 'vcpkg:PackageVersion', ...
    'The staged package version does not match the release version.');
assert(isempty(pkg.MissingDependencies), 'vcpkg:PackageDependencies', ...
    'Install the declared MATLAB package dependencies before packaging.');
if ~isfolder(options.OutputFolder)
    mkdir(options.OutputFolder);
end
artifacts = strings(1, 0);
toolboxOptions = [];
if any(options.Formats == "mpm")
    archive = fullfile(options.OutputFolder, artifactBase + "_mpm.zip");
    zip(archive, "*", toolboxFolder);
    artifacts(end+1) = archive;
end
if any(options.Formats == "toolbox")
    % Preserve the installer UUID and compatibility; package the hierarchy.
    toolboxOptions = matlab.addons.toolbox.ToolboxOptions( ...
        toolboxFolder, string(metadata.id), ...
        ToolboxName=string(metadata.displayName), ...
        ToolboxVersion=versionText, ...
        Summary=string(metadata.summary), ...
        Description=string(metadata.description), ...
        AuthorName=string(metadata.provider.name), ...
        AuthorEmail=string(metadata.provider.email), ...
        AuthorCompany=string(metadata.provider.organization), ...
        MinimumMatlabRelease=extractAfter(string(metadata.releaseCompatibility), ">="), ...
        MaximumMatlabRelease="");
    toolboxOptions.ToolboxGettingStartedGuide = ...
        fullfile(toolboxFolder, "gettingStarted.mlx");
    % MPM exposes its root; ToolboxOptions imports only member paths.
    toolboxOptions.ToolboxMatlabPath = unique([toolboxFolder; ...
        string(toolboxOptions.ToolboxMatlabPath(:))], 'stable');
    supportedPlatforms = toolboxOptions.SupportedPlatforms;
    supportedPlatforms.Glnxa64 = true;
    if isfield(supportedPlatforms, 'Mac')
        supportedPlatforms.Mac = true;
    else
        supportedPlatforms.Maci64 = true;
    end
    supportedPlatforms.MatlabOnline = false;
    supportedPlatforms.Win64 = true;
    toolboxOptions.SupportedPlatforms = supportedPlatforms;
    toolboxOptions.OutputFile = fullfile(options.OutputFolder, artifactBase + ".mltbx");
    matlab.addons.toolbox.packageToolbox(toolboxOptions);
    artifacts(end+1) = string(toolboxOptions.OutputFile);
end
assert(all(isfile(artifacts)), 'vcpkg:PackageMissing', ...
    'A requested release artifact was not created.');
end
