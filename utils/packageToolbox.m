function toolboxOptions = packageToolbox(toolboxVersion)
%packageToolbox - Build the legacy toolbox installer
%   toolboxOptions = packageToolbox builds the .mltbx distribution artifact
%   using the shared package definition's version. The output filename is
%   vcpkg-wrapper-toolbox-vVERSION.mltbx in the repository root.
%
%   toolboxOptions = packageToolbox(toolboxVersion) also specifies version
%   text or a scalar matlab.mpm.Version. The return value is ToolboxOptions.
%
%   See also packageVcpkg, readVcpkgPackage, matlab.mpm.Version

arguments
    toolboxVersion = ""
end

rootFolder = fileparts(fileparts(mfilename('fullpath')));
[~, toolboxOptions] = packageVcpkg(rootFolder, toolboxVersion, Formats="toolbox");
end
