classdef vcpkgIntegrationTest < matlab.unittest.TestCase
    % Builds the sample fmt dependency and checks the installed linkage.

    properties (TestParameter)
        buildDynamic = struct('dynamic', true, 'static', false);
    end

    methods (TestMethodSetup)
        function prepareManifest(testCase)
            testFolder = fileparts(mfilename('fullpath'));
            temporaryFolder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            testCase.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture(temporaryFolder.Folder));
            mkdir('manifest');
            copyfile(fullfile(testFolder, 'vcpkg.json'), fullfile('manifest', 'vcpkg.json'));
            copyfile(fullfile(testFolder, 'vcpkg-configuration.json'), ...
                fullfile('manifest', 'vcpkg-configuration.json'));
            systemPath = getenv('Path');
            testCase.addTeardown(@() setenv('Path', systemPath));
        end
    end

    methods (Test, TestTags = {'Integration'})
        function defaultsToDynamicHostLibraries(testCase)
            vcpkg.buildVcpkgDeps('manifest', '--x-install-root=../installed', 'buildHostOnly', true);

            installFolder = fullfile('installed', vcpkg.getHostTriplet(true));
            testCase.verifyTrue(isfile(fullfile(installFolder, 'include', 'fmt', 'format.h')));
            testCase.verifyNotEmpty(findSharedLibraries(installFolder));
        end

        function buildsHostLibraries(testCase, buildDynamic)
            vcpkg.buildVcpkgDeps('manifest', '--x-install-root=../installed', ...
                'buildHostOnly', true, 'buildDynamic', buildDynamic);

            installFolder = fullfile('installed', vcpkg.getHostTriplet(buildDynamic));
            testCase.verifyTrue(isfile(fullfile(installFolder, 'include', 'fmt', 'format.h')));
            testCase.verifyEqual(~isempty(findSharedLibraries(installFolder)), buildDynamic);
            testCase.verifyNotEmpty(findLinkLibraries(installFolder));
        end
    end

    methods (Test, TestTags = {'TargetIntegration'})
        function buildsStaticTargetLibraries(testCase, buildDynamic)
            targetTriplet = vcpkg.getTargetTriplet();
            testCase.assumeNotEmpty(targetTriplet, 'No supported embedded target is installed.');

            vcpkg.buildVcpkgDeps('manifest', '--x-install-root=../installed', ...
                'buildDynamic', buildDynamic);

            installFolder = fullfile('installed', targetTriplet);
            testCase.verifyTrue(isfile(fullfile(installFolder, 'include', 'fmt', 'format.h')));
            testCase.verifyNotEmpty(findLinkLibraries(installFolder));
            testCase.verifyEmpty(findSharedLibraries(installFolder));
        end
    end
end

function libraries = findSharedLibraries(installFolder)
libraries = [dir(fullfile(installFolder, 'bin', '*fmt*.dll')); ...
    dir(fullfile(installFolder, 'lib', '*fmt*.so*')); ...
    dir(fullfile(installFolder, 'lib', '*fmt*.dylib'))];
end

function libraries = findLinkLibraries(installFolder)
libraries = [dir(fullfile(installFolder, 'lib', '*fmt*.a')); ...
    dir(fullfile(installFolder, 'lib', '*fmt*.lib')); ...
    dir(fullfile(installFolder, 'lib', '*fmt*.so*')); ...
    dir(fullfile(installFolder, 'lib', '*fmt*.dylib'))];
end
