classdef buildVcpkgDepsTest < matlab.unittest.TestCase
    % Tests that invalid build inputs fail before any external command.

    properties (TestParameter)
        optionName = struct('linkage', 'buildDynamic', 'buildMode', 'buildRelease');
        invalidFlag = struct( ...
            'empty', struct('value', [], 'errorId', 'MATLAB:validation:IncompatibleSize'), ...
            'vector', struct('value', [true false], 'errorId', 'MATLAB:validation:IncompatibleSize'), ...
            'numericVector', struct('value', [0 1], 'errorId', 'MATLAB:validation:IncompatibleSize'));
        rootArgument = struct( ...
            'installEquals', '--x-install-root=installed', ...
            'installSeparate', '--x-install-root "install space"', ...
            'buildtrees', '--x-buildtrees-root=buildtrees', ...
            'packages', '--x-packages-root="packages"');
    end

    methods (Test, TestTags = {'Unit'})
        function rejectsInvalidFlag(testCase, optionName, invalidFlag)
            manifestFolder = fileparts(mfilename('fullpath'));

            testCase.verifyError(@() vcpkg.buildVcpkgDeps(manifestFolder, ...
                optionName, invalidFlag.value), invalidFlag.errorId);
        end

        function rejectsMissingManifestFolder(testCase)
            missingFolder = tempname;

            testCase.verifyError(@() vcpkg.buildVcpkgDeps(missingFolder), ...
                'MATLAB:validators:mustBeFolder');
        end

        function rejectsConflictingRoots(testCase, rootArgument)
            manifestFolder = fileparts(mfilename('fullpath'));

            testCase.verifyError(@() vcpkg.buildVcpkgDeps(manifestFolder, ...
                rootArgument, 'dependencyRoot', tempname), ...
                'vcpkg:buildVcpkgDeps:ConflictingRootArguments');
        end

        function rejectsNontextDependencyRoot(testCase)
            manifestFolder = fileparts(mfilename('fullpath'));

            testCase.verifyError(@() vcpkg.buildVcpkgDeps(manifestFolder, ...
                'dependencyRoot', 42), 'MATLAB:validators:mustBeTextScalar');
        end

        function rejectsNonscalarDependencyRoot(testCase)
            manifestFolder = fileparts(mfilename('fullpath'));

            testCase.verifyError(@() vcpkg.buildVcpkgDeps(manifestFolder, ...
                'dependencyRoot', ["one", "two"]), ...
                'MATLAB:validators:mustBeTextScalar');
        end
    end
end
