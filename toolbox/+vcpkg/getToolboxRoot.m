function toolboxRoot = getToolboxRoot
%getToolboxRoot Return the root folder of the installed vcpkg toolbox.
%   ROOT = vcpkg.getToolboxRoot returns the folder that contains the +vcpkg
%   package and shipped overlay triplets.

% Copyright 2026 The MathWorks, Inc.

toolboxRoot = coder.make.internal.transformPaths(fileparts(fileparts(mfilename('fullpath'))));

end
