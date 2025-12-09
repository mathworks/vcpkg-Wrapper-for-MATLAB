function toolboxOptions = packageToolbox(toolboxVersion)

arguments
    toolboxVersion matlab.mpm.Version = '0.0.0'
end

% Toolbox Parameter Configuration
toolboxOptions = matlab.addons.toolbox.ToolboxOptions("toolbox", "53137c5a-1016-4021-9e29-83f3951d3c9a");

toolboxOptions.ToolboxName = "vcpkg Wrapper for MATLAB";
toolboxOptions.ToolboxVersion = toolboxVersion.string;
toolboxOptions.Summary = "This toolbox wraps vcpkg to enable easy packet management in MATLAB projects.";
toolboxOptions.AuthorName = 'Pablo Romero';
toolboxOptions.AuthorEmail = "promero@mathworks.com";
toolboxOptions.AuthorCompany = "The MathWorks";
% toolboxOptions.ToolboxImageFile = "toolbox/toolboxIcon.jpeg";
toolboxOptions.ToolboxGettingStartedGuide = "toolbox/gettingStarted.mlx";
toolboxOptions.OutputFile = sprintf("vcpkg-wrapper-toolbox-v%s.mltbx",toolboxVersion.string);

toolboxOptions.MinimumMatlabRelease = "R2019b"; % R2024b is minimum required because of "arguments"
% toolboxOptions.MaximumMatlabRelease = "R2023a"; % Won't limit maximum MATLAB release
toolboxOptions.SupportedPlatforms.Glnxa64 = true;
toolboxOptions.SupportedPlatforms.Maci64 = true;
toolboxOptions.SupportedPlatforms.MatlabOnline = false;
toolboxOptions.SupportedPlatforms.Win64 = true;

% Generate toolbox
matlab.addons.toolbox.packageToolbox(toolboxOptions);

end