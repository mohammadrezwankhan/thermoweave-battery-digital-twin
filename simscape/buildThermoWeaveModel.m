function report = buildThermoWeaveModel(options)
%BUILDTHERMOWEAVEMODEL Product- and policy-aware Simscape adapter entry point.
%   REPORT = BUILDTHERMOWEAVEMODEL() inspects prerequisites without
%   fabricating a generated model. Structural generation is enabled only
%   after the repository custom-library policy has been explicitly resolved.
%
%   This adapter is intentionally separate from the portable graph core.
%   Generated libraries and models belong under simscape/models and are
%   excluded from version control.

arguments
    options.ProjectRoot (1, 1) string = string(fileparts(fileparts(mfilename("fullpath"))))
end

report = struct( ...
    "schemaVersion", "thermoweave.simscape-build/v1", ...
    "status", "NOT_RUN", ...
    "message", "", ...
    "projectRoot", options.ProjectRoot, ...
    "products", detectProducts(), ...
    "libraryPolicy", inspectLibraryPolicy(options.ProjectRoot), ...
    "generatedModel", "", ...
    "timestampUtc", string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'")));

if ~all([report.products.available])
    report.status = "SKIPPED_MISSING_PRODUCT";
    report.message = "Simulink, Simscape, and Simscape Battery are required.";
    return
end

if report.libraryPolicy.status ~= "RESOLVED"
    report.status = "SKIPPED_LIBRARY_POLICY_UNRESOLVED";
    report.message = "Resolve the .satk custom-library declaration before " + ...
        "structural model generation. No generated model was claimed.";
    return
end

% Model structure is authored through the repository's approved modeling
% workflow, not through hidden add_block/set_param calls in this file. Until
% that generated artifact and its manifest exist, execution remains skipped.
manifestPath = fullfile(options.ProjectRoot, "simscape", "models", ...
    "thermoweave-model-manifest.json");
if ~isfile(manifestPath)
    report.status = "SKIPPED_MODEL_NOT_GENERATED";
    report.message = "Products and library policy are available, but the " + ...
        "approved model generation workflow has not produced a manifest.";
    return
end

manifest = jsondecode(fileread(manifestPath));
report.status = "READY";
report.message = "A generated-model manifest is present; verify it before execution.";
if isfield(manifest, "modelFile")
    report.generatedModel = string(manifest.modelFile);
end
end

function products = detectProducts()
required = ["Simulink", "Simscape", "Simscape Battery"];
installed = ver;
names = string({installed.Name});
products = repmat(struct("name", "", "available", false, "version", ""), ...
    numel(required), 1);
for index = 1:numel(required)
    match = find(strcmpi(names, required(index)), 1);
    products(index).name = required(index);
    products(index).available = ~isempty(match);
    if ~isempty(match)
        products(index).version = string(installed(match).Version);
    end
end
end

function policy = inspectLibraryPolicy(projectRoot)
path = fullfile(projectRoot, ".satk", "reuse-libraries.json");
policy = struct("status", "UNRESOLVED", "path", string(path), ...
    "confirmedNone", false, "libraryCount", 0);
if ~isfile(path)
    return
end

try
    data = jsondecode(fileread(path));
catch exception
    policy.status = "INVALID";
    policy.errorIdentifier = string(exception.identifier);
    return
end

if isfield(data, "confirmedNone") && logical(data.confirmedNone)
    policy.status = "RESOLVED";
    policy.confirmedNone = true;
    return
end

if isfield(data, "libraries") && ~isempty(data.libraries)
    blockPolicy = fullfile(projectRoot, ".satk", "block-policy.json");
    knowledgeIndex = fullfile(projectRoot, ".satk", "library-kg", "index.md");
    policy.libraryCount = numel(data.libraries);
    if isfile(blockPolicy) && isfile(knowledgeIndex)
        policy.status = "RESOLVED";
    end
end
end
