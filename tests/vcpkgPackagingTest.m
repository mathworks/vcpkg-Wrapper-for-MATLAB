classdef vcpkgPackagingTest < matlab.unittest.TestCase
    % Verify installable artifacts and preservation of the legacy toolbox.

    properties
        RootFolder
        OutputFolder
    end

    properties (TestParameter)
        versionInput = struct('text', '1.2.3', 'tag', 'v1.2.3');
        unsupportedVersion = struct('prerelease', '1.2.3-beta', ...
            'build', '1.2.3+build');
    end

    methods (TestMethodSetup)
        function prepareOutput(testCase)
            testCase.RootFolder = fileparts(fileparts(mfilename('fullpath')));
            testCase.assumeFalse(isMATLABReleaseOlderThan('R2024b'), ...
                'Package authoring requires MATLAB R2024b or newer.');
            workFolder = fullfile(testCase.RootFolder, 'work');
            if ~isfolder(workFolder)
                mkdir(workFolder);
            end
            testCase.OutputFolder = string(tempname(workFolder));
            mkdir(testCase.OutputFolder);
            testCase.addTeardown(@() rmdir(testCase.OutputFolder, 's'));
        end
    end

    methods (Test, TestTags = {'Packaging'})
        function sourceDefinitionLoads(testCase)
            pkg = matlab.mpm.Package(fullfile(testCase.RootFolder, 'toolbox'));
            [metadata, version] = readVcpkgPackage(testCase.RootFolder);

            testCase.verifyEqual(pkg.Version, version);
            testCase.verifyEqual(pkg.ID, string(metadata.id));
            testCase.verifyEqual(pkg.DisplayName, string(metadata.displayName));
            testCase.verifyEmpty(pkg.Dependencies);
        end

        function artifactsShareVersionAndContents(testCase)
            manifest = fullfile(testCase.RootFolder, 'toolbox', 'resources', 'mpackage.json');
            before = fileread(manifest);

            artifacts = packageVcpkg(testCase.RootFolder, 'v1.2.3', ...
                OutputFolder=testCase.OutputFolder);
            mpmFolder = fullfile(testCase.OutputFolder, 'mpm');
            installerFolder = fullfile(testCase.OutputFolder, 'installer');
            unzip(artifacts(1), mpmFolder);
            unzip(artifacts(2), installerFolder);
            pkg = matlab.mpm.Package(mpmFolder);
            installedRoot = fullfile(installerFolder, 'fsroot');
            installerPkg = matlab.mpm.Package(installedRoot);

            testCase.verifyEqual(pkg.Version, matlab.mpm.Version('1.2.3'));
            testCase.verifyEqual(installerPkg.Version, pkg.Version);
            testCase.verifyEqual(installerPkg.ID, pkg.ID);
            testCase.verifyEqual(matlab.addons.toolbox.toolboxVersion(artifacts(2)), '1.2.3');
            testCase.verifyEqual(replace(artifacts(1), '_mpm.zip', '.mltbx'), artifacts(2));
            testCase.verifyEqual(fileread(manifest), before);
            verifyContents(testCase, mpmFolder, installedRoot);

            config = fileread(fullfile(installerFolder, 'metadata', 'configuration.xml'));
            requirements = fileread(fullfile(installerFolder, 'metadata', 'systemRequirements.xml'));
            testCase.verifySubstring(config, '<matlabPath></matlabPath>');
            testCase.verifySubstring(config, '<matlabPath>/overlay-triplets</matlabPath>');
            testCase.verifySubstring(config, '<gettingStartedDocPath>gettingStarted.mlx</gettingStartedDocPath>');
            testCase.verifySubstring(requirements, 'start="R2020b"');
            testCase.verifySubstring(requirements, 'end="latest"');
        end

        function defaultBuildUsesManifestVersion(testCase)
            [~, version] = readVcpkgPackage(testCase.RootFolder);

            artifacts = packageVcpkg(testCase.RootFolder, Formats="mpm", ...
                OutputFolder=testCase.OutputFolder);
            unzip(artifacts, fullfile(testCase.OutputFolder, 'mpm'));
            pkg = matlab.mpm.Package(fullfile(testCase.OutputFolder, 'mpm'));

            testCase.verifyEqual(pkg.Version, version);
            testCase.verifyNumElements(artifacts, 1);
        end

        function acceptsTextVersion(testCase, versionInput)
            [metadata, version] = readVcpkgPackage(testCase.RootFolder, versionInput);

            testCase.verifyEqual(version, matlab.mpm.Version('1.2.3'));
            testCase.verifyEqual(metadata.version, '1.2.3');
        end

        function acceptsVersionObject(testCase)
            expected = matlab.mpm.Version('1.2.3');

            [~, actual] = readVcpkgPackage(testCase.RootFolder, expected);

            testCase.verifyEqual(actual, expected);
        end

        function rejectsUnsupportedVersion(testCase, unsupportedVersion)
            testCase.verifyError(@() packageVcpkg(testCase.RootFolder, ...
                unsupportedVersion, OutputFolder=testCase.OutputFolder), ...
                'vcpkg:PackageVersion');
        end

        function legacyHelperKeepsFilenameAndReturnType(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture(testCase.RootFolder));
            version = matlab.mpm.Version('999.0.0');
            output = fullfile(testCase.RootFolder, ...
                "vcpkg-wrapper-toolbox-v" + string(version) + ".mltbx");
            testCase.assumeFalse(isfile(output), 'Avoid replacing an existing local artifact.');
            testCase.addTeardown(@() delete(output));

            opts = packageToolbox(version);

            testCase.verifyClass(opts, 'matlab.addons.toolbox.ToolboxOptions');
            testCase.verifyTrue(isfile(output));
            testCase.verifyEqual(string(opts.OutputFile), output);
            testCase.verifyEqual(matlab.addons.toolbox.toolboxVersion(output), char(string(version)));
        end
    end
end

function verifyContents(testCase, mpmFolder, installedRoot)
sourceRoot = fullfile(testCase.RootFolder, 'toolbox');
sourceFiles = relativeFiles(sourceRoot);
testCase.verifyEqual(relativeFiles(mpmFolder), sourceFiles);
testCase.verifyEmpty(setdiff(sourceFiles, relativeFiles(installedRoot)));
unchangedFiles = setdiff(sourceFiles, 'resources/mpackage.json');
for file = unchangedFiles
    testCase.verifyEqual(readBytes(fullfile(mpmFolder, file)), ...
        readBytes(fullfile(sourceRoot, file)), char(file));
    testCase.verifyEqual(readBytes(fullfile(installedRoot, file)), ...
        readBytes(fullfile(sourceRoot, file)), char(file));
end
end

function files = relativeFiles(folder)
entries = dir(fullfile(folder, '**', '*'));
entries = entries(~[entries.isdir]);
files = string(fullfile({entries.folder}, {entries.name}));
files = sort(replace(extractAfter(files, string(folder) + filesep), filesep, '/'));
end

function bytes = readBytes(file)
fileID = fopen(file, 'rb');
cleanup = onCleanup(@() fclose(fileID));
bytes = fread(fileID, Inf, '*uint8');
end
