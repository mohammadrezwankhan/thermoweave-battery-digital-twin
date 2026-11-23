function manifest = packageRelease()
%PACKAGERELEASE Create a reproducible source-and-evidence ZIP archive.

root = fileparts(fileparts(mfilename("fullpath")));
releaseFolder = fullfile(root, "release");
if ~isfolder(releaseFolder)
    mkdir(releaseFolder);
end
archive = fullfile(releaseFolder, "thermoweave-source.zip");
include = ["README.md", "LICENSE", "CITATION.cff", "CHANGELOG.md", ...
    "PROVENANCE.md", "THIRD_PARTY_NOTICES.md", "ENVIRONMENT.md", ...
    "PROJECT_CHARTER.md", "ARCHITECTURE.md", "DECISIONS.md", ...
    "RISK_REGISTER.md", "RED_TEAM_REPORT.md", "TASKS.md", "ROADMAP.md", ...
    "CONTRIBUTING.md", "CODE_OF_CONDUCT.md", "SECURITY.md", ...
    "ThermoWeave.prj", "startup.m", "runDemo.m", "buildfile.m", ...
    "src", "config", "examples", "simscape", "tests", "tools", ...
    "docs", "artifacts", "resources", "manuscript", ".github"];
oldFolder = cd(root);
restoreFolder = onCleanup(@() cd(oldFolder));
revision = currentGitCommit();
[status, listing] = system("git -c core.quotePath=false ls-tree -r --name-only " + ...
    revision + " -- " + strjoin(include, " "));
if status ~= 0
    error("thermoweave:release:SourceInventory", "Cannot list release source files.");
end
entries = splitlines(string(listing));
entries = entries(entries ~= "");
if isempty(entries) || ~all(isfile(fullfile(root, entries)))
    error("thermoweave:release:SourceInventory", "Tracked release source files are missing.");
end
existing = include(ismember(include, extractBefore(entries + "/", "/")));
% Use the working copies of tracked paths so freshly generated reports ship.
zip(archive, cellstr(entries), root);
manifest = struct("archive", string(archive), "bytes", ...
    dir(archive).bytes, "sha256", thermoweave.util.hashFile(archive), ...
    "gitCommit", revision, "contents", existing);
manifestPath = fullfile(releaseFolder, "release-manifest.json");
portableManifest = manifest;
portableManifest.archive = "release/thermoweave-source.zip";
file = fopen(manifestPath, "w");
if file < 0
    error("thermoweave:release:IO", "Unable to write release manifest.");
end
cleanup = onCleanup(@() fclose(file));
fwrite(file, jsonencode(portableManifest), "char");
end

function revision = currentGitCommit()
[status, output] = system("git rev-parse HEAD");
revision = string(strtrim(output));
if status ~= 0 || isempty(regexp(revision, "^[0-9a-f]{40}$", "once"))
    error("thermoweave:release:SourceInventory", "Cannot resolve the release source commit.");
end
end
