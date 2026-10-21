classdef vcpkgPackagingTest < matlab.unittest.TestCase
    % Verify the toolbox installer and its embedded package metadata.

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

        function installerContainsVersionedPackageMetadata(testCase)
            manifest = fullfile(testCase.RootFolder, 'toolbox', 'resources', 'mpackage.json');
            before = fileread(manifest);

            artifact = packageVcpkg(testCase.RootFolder, 'v1.2.3', ...
                'OutputFolder',testCase.OutputFolder);
            installerFolder = fullfile(testCase.OutputFolder, 'installer');
            unzip(artifact, installerFolder);
            installedRoot = fullfile(installerFolder, 'fsroot');
            installerPkg = matlab.mpm.Package(installedRoot);
            [metadata, version] = readVcpkgPackage(testCase.RootFolder, 'v1.2.3');

            testCase.verifyEqual(installerPkg.Version, version);
            testCase.verifyEqual(installerPkg.ID, string(metadata.id));
            testCase.verifyEqual(matlab.addons.toolbox.toolboxVersion(artifact), '1.2.3');
            testCase.verifyEqual(fileread(manifest), before);
            verifyContents(testCase, installedRoot);

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

            artifact = packageVcpkg(testCase.RootFolder, ...
                'OutputFolder', testCase.OutputFolder);
            installerFolder = fullfile(testCase.OutputFolder, 'installer');
            unzip(artifact, installerFolder);
            pkg = matlab.mpm.Package(fullfile(installerFolder, 'fsroot'));

            testCase.verifyEqual(pkg.Version, version);
            testCase.verifyEqual(matlab.addons.toolbox.toolboxVersion(artifact), char(string(version)));
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
                unsupportedVersion, 'OutputFolder', testCase.OutputFolder), ...
                'vcpkg:PackageVersion');
        end

        function buildKeepsFilenameAndReturnType(testCase)
            version = matlab.mpm.Version('1.2.3');
            output = fullfile(testCase.OutputFolder, ...
                "vcpkgWrapper-" + string(version) + ".mltbx");

            [artifact, opts] = packageVcpkg(testCase.RootFolder, version, ...
                'OutputFolder', testCase.OutputFolder);

            testCase.verifyClass(opts, 'matlab.addons.toolbox.ToolboxOptions');
            testCase.verifyEqual(artifact, output);
            testCase.verifyTrue(isfile(output));
            testCase.verifyEqual(relativeFiles(testCase.OutputFolder), ...
                "vcpkgWrapper-" + string(version) + ".mltbx");
            testCase.verifyEqual(string(opts.OutputFile), output);
            testCase.verifyEqual(matlab.addons.toolbox.toolboxVersion(output), char(string(version)));
        end
    end
end

function verifyContents(testCase, installedRoot)
sourceRoot = fullfile(testCase.RootFolder, 'toolbox');
sourceFiles = relativeFiles(sourceRoot);
packagedFiles = sort([sourceFiles, "README.md"]);
testCase.verifyEmpty(setdiff(packagedFiles, relativeFiles(installedRoot)));
readmeFile = fullfile(testCase.RootFolder, 'README.md');
testCase.verifyEqual(readBytes(fullfile(installedRoot, 'README.md')), readBytes(readmeFile));
metadata = jsondecode(fileread(fullfile(installedRoot, 'resources', 'mpackage.json')));
if isMATLABReleaseOlderThan('R2026b')
    testCase.verifyEqual(metadata.description, fileread(readmeFile));
else
    pkg = matlab.mpm.Package(installedRoot);
    testCase.verifyEqual(string(metadata.readme), "README.md");
    testCase.verifyEqual(string(metadata.schemaVersion), "1.2.0");
    testCase.verifyFalse(isfield(metadata, 'description'));
    testCase.verifyEqual(string(pkg.Readme), "README.md");
end
unchangedFiles = setdiff(sourceFiles, 'resources/mpackage.json');
for file = unchangedFiles
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
