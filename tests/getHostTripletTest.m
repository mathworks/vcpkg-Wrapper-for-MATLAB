classdef getHostTripletTest < matlab.unittest.TestCase
    % Tests for host triplet linkage and input validation.

    properties (TestParameter)
        buildDynamic = struct('dynamic', true, 'static', false);
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
        function defaultsToDynamic(testCase)
            expected = getExpectedTriplet(true);

            actual = vcpkg.getHostTriplet();

            testCase.verifyEqual(actual, expected);
        end

        function selectsHostLinkage(testCase, buildDynamic)
            expected = getExpectedTriplet(buildDynamic);

            actual = vcpkg.getHostTriplet(buildDynamic);

            testCase.verifyEqual(actual, expected);
        end

        function rejectsInvalidFlag(testCase, invalidFlag)
            testCase.verifyError(@() vcpkg.getHostTriplet(invalidFlag.value), invalidFlag.errorId);
        end
    end
end

function triplet = getExpectedTriplet(buildDynamic)
if ispc
    compiler = mex.getCompilerConfigurations('C++', 'Selected');
    if isempty(compiler) || contains(compiler.ShortName, 'mingw', 'IgnoreCase', true)
        triplets = {'x64-mingw-static', 'x64-mingw-dynamic'};
    else
        triplets = {'x64-windows-static-md', 'x64-windows'};
    end
elseif ismac && strcmp(computer('arch'), 'maca64')
    triplets = {'arm64-osx', 'arm64-osx-dynamic'};
elseif ismac
    triplets = {'x64-osx', 'x64-osx-dynamic'};
else
    triplets = {'x64-linux', 'x64-linux-dynamic'};
end
triplet = triplets{1 + double(buildDynamic)};
end
