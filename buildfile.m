function plan = buildfile
import matlab.buildtool.Task
import matlab.buildtool.tasks.CodeIssuesTask
import matlab.buildtool.tasks.TestTask
import matlab.unittest.Verbosity

% Create a plan with no tasks
plan = buildplan;

% Add a task to identify and export the code issues
plan("check") = CodeIssuesTask(["toolbox", "tests"],...
    WarningThreshold=0,...
    Results="code-issues/results.sarif");

plan("test") = Task(...
    "Description","Build toolbox dependencies with vcpkg",...
    "Inputs",["toolbox", "tests/vcpkg.json"],...
    "Outputs",[fullfile("work",vcpkg.getHostTriplet), fullfile("work",vcpkg.getTargetTriplet)],...
    Actions = {@(~) vcpkg.buildVcpkgDeps('tests','--x-install-root=../work')});

% Package toolbox
plan("package") = Task(...
    Description = "Package toolbox", ...
    Dependencies = ["check" "test"], ...
    Actions = {@(~,toolboxVersion) packageToolbox(erase(toolboxVersion,"v"))});

% Make the "test" task the default task in the plan
plan.DefaultTasks = ["check" "test"];

end