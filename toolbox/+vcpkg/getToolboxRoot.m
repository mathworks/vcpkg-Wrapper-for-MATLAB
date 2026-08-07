function toolboxRoot = getToolboxRoot
%getToolboxRoot Return the root folder of the installed vcpkg toolbox.
%   ROOT = vcpkg.getToolboxRoot returns the folder that contains the +vcpkg
%   package and shipped overlay triplets.

% Copyright 2025 The MathWorks, Inc.

toolboxRoot = fileparts(fileparts(mfilename('fullpath')));

end