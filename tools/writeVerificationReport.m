function report = writeVerificationReport()
%WRITEVERIFICATIONREPORT Persist machine-readable local evidence.

root = fileparts(fileparts(mfilename("fullpath")));
resultFile = fullfile(root, "results", "test-results.xml");
if ~isfile(resultFile) || sourceNewerThan(resultFile, root)
    testResults = runtests(fullfile(root, "tests"), IncludeSubfolders=true);
    testCount = numel(testResults);
    failures = sum([testResults.Failed]);
    incomplete = sum([testResults.Incomplete]);
else
    document = xmlread(resultFile);
    suites = document.getElementsByTagName("testsuite");
    testCount = 0;
    failures = 0;
    incomplete = 0;
    for index = 0:(suites.getLength() - 1)
        suite = suites.item(index);
        testCount = testCount + attributeNumber(suite, "tests");
        failures = failures + attributeNumber(suite, "failures") + ...
            attributeNumber(suite, "errors");
        incomplete = incomplete + attributeNumber(suite, "skipped");
    end
end

coverageRate = NaN;
coverageFile = fullfile(root, "results", "coverage.xml");
if isfile(coverageFile)
    coverageDocument = xmlread(coverageFile);
    coverageRoot = coverageDocument.getDocumentElement();
    coverageRate = str2double(string(coverageRoot.getAttribute("line-rate")));
end

codeIssueCount = NaN;
codeIssueFile = fullfile(root, "results", "code-issues.sarif");
if isfile(codeIssueFile)
    codeReport = jsondecode(fileread(codeIssueFile));
    if isfield(codeReport.runs(1), "results")
        codeIssueCount = numel(codeReport.runs(1).results);
    else
        codeIssueCount = 0;
    end
end

demo = runDemo();
adapter = buildThermoWeaveModel(ProjectRoot=string(root));
report = struct( ...
    "schemaVersion", "thermoweave.verification/v1", ...
    "matlabRelease", string(version("-release")), ...
    "testCount", testCount, ...
    "passed", testCount - failures - incomplete, ...
    "failed", failures, ...
    "incomplete", incomplete, ...
    "statementCoverage", coverageRate, ...
    "codeAnalyzerFindings", codeIssueCount, ...
    "demo", struct( ...
        "peakTemperature_K", demo.metrics.peakTemperature_K, ...
        "coolingEnergy_J", demo.metrics.coolingEnergy_J, ...
        "energyResidualNormalized", demo.energyResidualNormalized, ...
        "scenarioHash", string(demo.metadata.scenarioHash)), ...
    "simscapeAdapterStatus", string(adapter.status), ...
    "gitCommit", string(demo.metadata.gitCommit), ...
    "timestampUtc", string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'")));

path = fullfile(root, "artifacts", "reports", "verification.json");
file = fopen(path, "w");
if file < 0
    error("thermoweave:verification:IO", ...
        "Unable to write verification report.");
end
cleanup = onCleanup(@() fclose(file));
fwrite(file, jsonencode(report), "char");
end

function newer = sourceNewerThan(resultFile, root)
reportTime = dir(resultFile).datenum;
patterns = [fullfile(root, "tests", "**", "*.m"), ...
    fullfile(root, "src", "**", "*.m")];
newer = false;
for pattern = patterns
    files = dir(pattern);
    if ~isempty(files) && max([files.datenum]) > reportTime
        newer = true;
        return
    end
end
end

function value = attributeNumber(node, name)
value = str2double(string(node.getAttribute(name)));
if isnan(value)
    value = 0;
end
end
