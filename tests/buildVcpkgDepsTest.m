classdef buildVcpkgDepsTest < matlab.unittest.TestCase
    % Tests that invalid build inputs fail before any external command.

    properties (TestParameter)
        invalidFlag = struct( ...
            'empty', struct('value', [], 'errorId', 'MATLAB:validation:IncompatibleSize'), ...
            'vector', struct('value', [true false], 'errorId', 'MATLAB:validation:IncompatibleSize'), ...
            'numeric', struct('value', 1, 'errorId', 'MATLAB:validators:mustBeA'), ...
            'character', struct('value', 'true', 'errorId', 'MATLAB:validation:IncompatibleSize'), ...
            'string', struct('value', "false", 'errorId', 'MATLAB:validators:mustBeA'), ...
            'cell', struct('value', {{true}}, 'errorId', 'MATLAB:validators:mustBeA'), ...
            'nan', struct('value', NaN, 'errorId', 'MATLAB:validators:mustBeA'));
    end

    methods (Test, TestTags = {'Unit'})
        function rejectsInvalidFlag(testCase, invalidFlag)
            manifestFolder = fileparts(mfilename('fullpath'));

            testCase.verifyError(@() vcpkg.buildVcpkgDeps(manifestFolder, ...
                'buildDynamic', invalidFlag.value), invalidFlag.errorId);
        end

        function rejectsMissingManifestFolder(testCase)
            missingFolder = tempname;

            testCase.verifyError(@() vcpkg.buildVcpkgDeps(missingFolder), ...
                'MATLAB:validators:mustBeFolder');
        end
    end
end
