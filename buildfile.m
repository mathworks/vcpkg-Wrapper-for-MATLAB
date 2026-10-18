function plan = buildfile
%BUILDFILE - Define verification and toolbox packaging tasks
%   PLAN = BUILDFILE defines code checks, runtime tests, packaging tests,
%   and toolbox builds. Release tags override the manifest version.
%
%   See also buildtool, packageVcpkg
import matlab.buildtool.Task
import matlab.buildtool.tasks.*

% Create a plan with no tasks
plan = buildplan;

% Add a task to identify and export the code issues
plan("check") = CodeIssuesTask(["toolbox", "tests", "utils", "buildfile.m"], ...
    WarningThreshold=0, ...
    Results="code-issues/results.sarif");

plan("packagingTest") = TestTask("tests", ...
    Description="Verify the toolbox and its embedded package metadata", ...
    Tag="Packaging", ...
    SourceFiles=["utils", "buildfile.m"], ...
    TestResults="results/packagingTestResults.xml");
trackSupportingFiles(plan("packagingTest"), ["toolbox", "resources/project", "README.md"]);

plan("unit") = TestTask("tests", ...
    Description="Run MATLAB unit tests", ...
    Tag="Unit", ...
    SourceFiles="toolbox", ...
    TestResults="results/testResults.xml");

plan("integration") = TestTask("tests", ...
    Description="Test host linkage and Release-only or Debug/Release builds", ...
    Tag="Integration", ...
    SourceFiles="toolbox", ...
    TestResults="results/integrationTestResults.xml");
trackSupportingFiles(plan("integration"), ...
    ["tests/vcpkg.json", "tests/vcpkg-configuration.json"]);

plan("integrationWithTarget") = TestTask("tests", ...
    Description="Test static Release-only targets with all host build modes", ...
    Tag="TargetIntegration", ...
    SourceFiles="toolbox", ...
    TestResults="results/targetIntegrationTestResults.xml");
trackSupportingFiles(plan("integrationWithTarget"), ...
    ["tests/vcpkg.json", "tests/vcpkg-configuration.json"]);

plan("test") = Task( ...
    Description="Run unit and host integration tests", ...
    Dependencies=["unit" "integration"]);

% Save the toolbox installer in the release folder.
plan("release") = Task( ...
    Description="Build the toolbox release", ...
    Dependencies=["check" "test" "packagingTest"], ...
    Actions=@releaseTask, ...
    DisableIncremental=true, ...
    Outputs="release/vcpkg-wrapper-toolbox-v*.mltbx");

% Run all test tasks by default; GitHub Actions omits target integration.
plan.DefaultTasks = ["check" "unit" "integration" "packagingTest"];
if ~strcmpi(getenv("GITHUB_ACTIONS"), "true")
    plan.DefaultTasks(end+1) = "integrationWithTarget";
end

end

function trackSupportingFiles(task, files)
% R2024b tracks supporting files through task inputs instead of a property.
if isprop(task, "SupportingFiles")
    task.SupportingFiles = files;
else
    task.Inputs.SupportingFiles = matlab.buildtool.io.FileCollection.fromPaths(files);
end
end

function releaseTask(context, version)
arguments
    context
    version = githubReleaseVersion()
end
artifact = packageVcpkg(context.Plan.RootFolder, version);
info = dir(artifact);
context.log(sprintf("Package: %s (%.1f KB)", artifact, info.bytes / 1024));
end

function version = githubReleaseVersion()
version = "";
if strcmp(getenv("GITHUB_REF_TYPE"), "tag")
    version = getenv("GITHUB_REF_NAME");
end
end
