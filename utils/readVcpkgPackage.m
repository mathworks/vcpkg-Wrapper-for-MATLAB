function [metadata, version] = readVcpkgPackage(rootFolder, version)
%readVcpkgPackage - Read shared package and toolbox metadata
%   METADATA = readVcpkgPackage(rootFolder) reads the package definition
%   in toolbox/resources/mpackage.json.
%
%   [METADATA,VERSION] = readVcpkgPackage(...) also returns the version
%   as a scalar matlab.mpm.Version object.
%
%   [...] = readVcpkgPackage(rootFolder,VERSION) applies a release version
%   to the returned metadata. VERSION accepts text, a leading-v release
%   tag, or a scalar matlab.mpm.Version. The source file is unchanged.
%
%   See also packageVcpkg, matlab.mpm.Version

arguments
    rootFolder {mustBeTextScalar}
    version = ""
end

metadata = jsondecode(fileread(fullfile(rootFolder, ...
    "toolbox", "resources", "mpackage.json")));
if ~isa(version, "matlab.mpm.Version")
    mustBeTextScalar(version);
    version = string(version);
    if version == ""
        version = string(metadata.version);
    end
    if startsWith(version, "v")
        version = extractAfter(version, 1);
    end
    version = matlab.mpm.Version(version);
end
assert(isscalar(version) && isempty(version.Prerelease) && ...
    isempty(version.Build), 'vcpkg:PackageVersion', ...
    'Toolbox versions cannot contain prerelease or build metadata.');
metadata.version = char(string(version));
% Preserve JSON arrays when MATLAB decodes a single entry as a scalar struct.
if isstruct(metadata.folders)
    metadata.folders = num2cell(metadata.folders);
end
if isstruct(metadata.dependencies)
    metadata.dependencies = num2cell(metadata.dependencies);
end
assert(~isempty(regexp(metadata.releaseCompatibility, ...
    '^>=R\d{4}[ab]$', 'once')), 'vcpkg:PackageCompatibility', ...
    'Use a minimum release constraint (>=RYYYYa or >=RYYYYb).');
end
