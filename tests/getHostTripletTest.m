classdef getHostTripletTest < matlab.unittest.TestCase
    % Tests for host triplet linkage and input validation.

    properties (TestParameter)
        buildDynamic = struct('dynamic', true, 'static', false);
        buildRelease = struct('releaseOnly', true, 'debugAndRelease', false);
        convertibleFlag = struct('zero', 0, 'one', 1, 'nonzero', 2, 'negative', -1);
        invalidFlag = struct( ...
            'empty', struct('value', [], 'errorId', 'MATLAB:validation:IncompatibleSize'), ...
            'vector', struct('value', [true false], 'errorId', 'MATLAB:validation:IncompatibleSize'), ...
            'numericVector', struct('value', [0 1], 'errorId', 'MATLAB:validation:IncompatibleSize'));
    end

    methods (TestMethodSetup)
        function suppressUnavailableReleaseWarning(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                'vcpkg:getHostTriplet:ReleaseTripletUnavailable'));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function defaultsToDynamicRelease(testCase)
            expected = getExpectedTriplet(true, true);

            actual = vcpkg.getHostTriplet();

            testCase.verifyEqual(actual, expected);
        end

        function defaultsToReleaseWithLinkage(testCase, buildDynamic)
            expected = getExpectedTriplet(buildDynamic, true);

            actual = vcpkg.getHostTriplet(buildDynamic);

            testCase.verifyEqual(actual, expected);
        end

        function selectsHostBuildMode(testCase, buildDynamic, buildRelease)
            expected = getExpectedTriplet(buildDynamic, buildRelease);

            actual = vcpkg.getHostTriplet(buildDynamic, buildRelease);

            testCase.verifyEqual(actual, expected);
        end

        function rejectsInvalidFlag(testCase, invalidFlag)
            testCase.verifyError(@() vcpkg.getHostTriplet(invalidFlag.value), invalidFlag.errorId);
        end

        function convertsLinkageFlag(testCase, convertibleFlag)
            expected = getExpectedTriplet(logical(convertibleFlag), true);

            actual = vcpkg.getHostTriplet(convertibleFlag);

            testCase.verifyEqual(actual, expected);
        end

        function convertsReleaseFlag(testCase, convertibleFlag)
            expected = getExpectedTriplet(true, logical(convertibleFlag));

            actual = vcpkg.getHostTriplet(true, convertibleFlag);

            testCase.verifyEqual(actual, expected);
        end

        function rejectsInvalidReleaseFlag(testCase, invalidFlag)
            testCase.verifyError(@() vcpkg.getHostTriplet(true, invalidFlag.value), invalidFlag.errorId);
        end
    end
end

function triplet = getExpectedTriplet(buildDynamic, buildRelease)
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
if buildRelease
    releaseTriplet = [triplet, '-release'];
    tripletFolder = fullfile(getenv('VCPKG_ROOT'), 'triplets');
    hasReleaseTriplet = isfile(fullfile(tripletFolder, [releaseTriplet, '.cmake'])) || ...
        isfile(fullfile(tripletFolder, 'community', [releaseTriplet, '.cmake']));
    if ~buildDynamic || contains(triplet, 'mingw') || hasReleaseTriplet
        triplet = releaseTriplet;
    end
elseif strcmp(triplet, 'x64-windows-static-md')
    tripletFolder = fullfile(getenv('VCPKG_ROOT'), 'triplets');
    hasStaticMdTriplet = isfile(fullfile(tripletFolder, [triplet, '.cmake'])) || ...
        isfile(fullfile(tripletFolder, 'community', [triplet, '.cmake']));
    if ~hasStaticMdTriplet
        triplet = 'x64-windows-static';
    end
end
end
