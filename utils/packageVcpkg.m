function [artifact, toolboxOptions] = packageVcpkg(rootFolder, version, options)
%packageVcpkg - Build a toolbox installer with embedded package metadata
%   ARTIFACT = packageVcpkg(rootFolder) builds a toolbox installer in
%   rootFolder/release using toolbox/resources/mpackage.json.
%
%   [...] = packageVcpkg(rootFolder,VERSION) also specifies release
%   version text, a leading-v tag, or a scalar matlab.mpm.Version object.
%
%   [...] = packageVcpkg(...,OutputFolder=FOLDER) changes the destination.
%
%   [ARTIFACT,toolboxOptions] = packageVcpkg(...) also returns the
%   ToolboxOptions used for the installer.
%
%   See also readVcpkgPackage, matlab.mpm.Package

arguments
    rootFolder {mustBeTextScalar}
    version = ""
    options.OutputFolder {mustBeTextScalar} = fullfile(rootFolder, "release")
end

[metadata, version] = readVcpkgPackage(rootFolder, version);
versionText = string(version);
artifactBase = metadata.name + "-" + versionText;
workFolder = fullfile(rootFolder, "work");
if ~isfolder(workFolder)
    mkdir(workFolder);
end
stagingFolder = string(tempname(workFolder));
mkdir(stagingFolder);
cleanup = onCleanup(@() rmdir(stagingFolder, 's'));
toolboxFolder = fullfile(stagingFolder, "toolbox");
copyfile(fullfile(rootFolder, "toolbox"), toolboxFolder);
readmeFile = fullfile(toolboxFolder, "README.md");
copyfile(fullfile(rootFolder, "README.md"), readmeFile);
stagedMetadata = metadata;
if isMATLABReleaseOlderThan('R2026b')
    stagedMetadata.description = fileread(readmeFile);
else
    stagedMetadata = rmfield(stagedMetadata, 'description');
    stagedMetadata.readme = 'README.md';
    stagedMetadata.schemaVersion = '1.2.0';
end
writelines(jsonencode(stagedMetadata, PrettyPrint=true), ...
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
artifact = string(toolboxOptions.OutputFile);
assert(isfile(artifact), 'vcpkg:PackageMissing', ...
    'The toolbox installer was not created.');
end
