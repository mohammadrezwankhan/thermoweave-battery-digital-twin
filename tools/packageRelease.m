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
    "docs", "artifacts", "resources", ".github"];
existing = include(arrayfun(@(item) isfile(fullfile(root, item)) || ...
    isfolder(fullfile(root, item)), include));
oldFolder = cd(root);
restoreFolder = onCleanup(@() cd(oldFolder));
zip(archive, existing);
manifest = struct("archive", string(archive), "bytes", ...
    dir(archive).bytes, "sha256", thermoweave.util.hashFile(archive), ...
    "contents", existing);
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
