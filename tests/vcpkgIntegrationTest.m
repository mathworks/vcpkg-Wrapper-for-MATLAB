classdef vcpkgIntegrationTest < matlab.unittest.TestCase
    % Builds the sample fmt dependency and checks the installed linkage.

    properties (TestParameter)
        buildDynamic = struct('dynamic', true, 'static', false);
        buildRelease = struct('releaseOnly', true, 'debugAndRelease', false);
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
        function convertsNumericBuildOptions(testCase, buildDynamic, buildRelease)
            triplet = vcpkg.getHostTriplet(buildDynamic, buildRelease);
            releaseOnly = endsWith(triplet, '-release');

            vcpkg.buildVcpkgDeps('manifest', '--x-install-root=../installed', ...
                'buildHostOnly', true, 'buildDynamic', 2*double(buildDynamic), ...
                'buildRelease', 2*double(buildRelease));

            installFolder = fullfile('installed', triplet);
            testCase.verifyTrue(isfile(fullfile(installFolder, 'include', 'fmt', 'format.h')));
            testCase.verifyNotEmpty(findLinkLibraries(installFolder));
            testCase.verifyEqual(~isempty(findSharedLibraries(installFolder)), buildDynamic);
            testCase.verifyEqual(~isempty(findLinkLibraries(fullfile(installFolder, 'debug'))), ~releaseOnly);
        end

        function defaultsToDynamicHostLibraries(testCase)
            triplet = vcpkg.getHostTriplet(true);
            releaseOnly = endsWith(triplet, '-release');

            paths = vcpkg.buildVcpkgDeps('manifest', '--x-install-root=../installed', 'buildHostOnly', true);

            installFolder = fullfile('installed', triplet);
            testCase.verifyTrue(isfile(fullfile(installFolder, 'include', 'fmt', 'format.h')));
            testCase.verifyNotEmpty(findSharedLibraries(installFolder));
            testCase.verifyEqual(~isempty(findLinkLibraries(fullfile(installFolder, 'debug'))), ~releaseOnly);
            testCase.verifyEqual(~isempty(findSharedLibraries(fullfile(installFolder, 'debug'))), ~releaseOnly);
            testCase.verifyEqual(paths.installRoot, fullfile(pwd, 'installed'));
            testCase.verifyEqual(paths.hostDir, fullfile(pwd, installFolder));
            testCase.verifyEqual(paths.targetDir, paths.hostDir);
        end

        function buildsHostWithSpaces(testCase)
            copyfile('manifest', 'manifest space');

            paths = vcpkg.buildVcpkgDeps('manifest space', ...
                'buildHostOnly', true);

            testCase.verifyEqual(paths.installRoot, ...
                fullfile(pwd, 'manifest space', 'vcpkg_installed'));
            testCase.verifyTrue(isfile(fullfile(paths.hostDir, 'include', 'fmt', 'format.h')));
            testCase.verifyNotEmpty(findSharedLibraries(paths.hostDir));
            testCase.verifyEqual(paths.targetDir, paths.hostDir);
        end

        function buildsHostLibraries(testCase, buildDynamic, buildRelease)
            triplet = vcpkg.getHostTriplet(buildDynamic, buildRelease);
            releaseOnly = endsWith(triplet, '-release');

            vcpkg.buildVcpkgDeps('manifest', '--x-install-root=../installed', ...
                'buildHostOnly', true, 'buildDynamic', buildDynamic, 'buildRelease', buildRelease);

            installFolder = fullfile('installed', triplet);
            testCase.verifyTrue(isfile(fullfile(installFolder, 'include', 'fmt', 'format.h')));
            testCase.verifyEqual(~isempty(findSharedLibraries(installFolder)), buildDynamic);
            testCase.verifyNotEmpty(findLinkLibraries(installFolder));
            testCase.verifyEqual(~isempty(findLinkLibraries(fullfile(installFolder, 'debug'))), ~releaseOnly);
            testCase.verifyEqual(~isempty(findSharedLibraries(fullfile(installFolder, 'debug'))), ...
                buildDynamic && ~releaseOnly);
        end
    end

    methods (Test, TestTags = {'TargetIntegration'})
        function buildsDefaultQnxRootWithSpaces(testCase)
            assumeWindowsQnx(testCase);
            copyfile('manifest', 'manifest space');

            [~, before] = system('subst');

            paths = vcpkg.buildVcpkgDeps('manifest space', '--binarysource=clear');

            [~, after] = system('subst');
            testCase.verifyEqual(after, before);
            testCase.verifyEqual(paths.installRoot, ...
                fullfile(pwd, 'manifest space', 'vcpkg_installed'));
            testCase.verifyTrue(isfile(fullfile(paths.targetDir, 'include', 'fmt', 'format.h')));
            testCase.verifyNotEmpty(findLinkLibraries(paths.targetDir));
        end

        function buildsForwardedQnxRootsWithSpaces(testCase)
            assumeWindowsQnx(testCase);
            [~, before] = system('subst');

            paths = vcpkg.buildVcpkgDeps('manifest', ...
                {'--x-install-root="../install space"', ...
                '--x-buildtrees-root="../build space"', ...
                '--x-packages-root="../package space"', '--binarysource=clear'});

            [~, after] = system('subst');
            testCase.verifyEqual(after, before);
            testCase.verifyEqual(paths.installRoot, fullfile(pwd, 'install space'));
            testCase.verifyEqual(paths.buildtreesRoot, fullfile(pwd, 'build space'));
            testCase.verifyEqual(paths.packagesRoot, fullfile(pwd, 'package space'));
            testCase.verifyNotEmpty(findLinkLibraries(paths.targetDir));
        end

        function removesQnxMappingAfterBuildFailure(testCase)
            assumeWindowsQnx(testCase);
            copyfile('manifest', 'manifest space');
            [~, before] = system('subst');

            testCase.verifyError(@() vcpkg.buildVcpkgDeps('manifest space', ...
                '--invalid-vcpkg-option'), 'vcpkg:buildVcpkgDeps:CommandFailed');

            [~, after] = system('subst');
            testCase.verifyEqual(after, before);
        end

        function buildsStaticTargetLibraries(testCase, buildDynamic, buildRelease)
            targetTriplet = vcpkg.getTargetTriplet();
            testCase.assumeNotEmpty(targetTriplet, 'No supported embedded target is installed.');

            vcpkg.buildVcpkgDeps('manifest', '--x-install-root=../installed', ...
                'buildDynamic', buildDynamic, 'buildRelease', buildRelease);

            installFolder = fullfile('installed', targetTriplet);
            testCase.verifyTrue(isfile(fullfile(installFolder, 'include', 'fmt', 'format.h')));
            testCase.verifyNotEmpty(findLinkLibraries(installFolder));
            testCase.verifyEmpty(findSharedLibraries(installFolder));
            testCase.verifyEmpty(findLinkLibraries(fullfile(installFolder, 'debug')));
            testCase.verifyEmpty(findSharedLibraries(fullfile(installFolder, 'debug')));
        end
    end
end

function assumeWindowsQnx(testCase)
testCase.assumeTrue(ispc && contains(vcpkg.getTargetTriplet(), 'qnx'));
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
