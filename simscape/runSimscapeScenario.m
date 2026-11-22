function adapterResult = runSimscapeScenario(config, options)
%RUNSIMSCAPESCENARIO Run a generated model or return an explicit skip record.
%   This function never converts missing infrastructure into a passing run.

arguments
    config
    options.ProjectRoot (1, 1) string = string(fileparts(fileparts(mfilename("fullpath"))))
end

buildReport = buildThermoWeaveModel(ProjectRoot=options.ProjectRoot);
adapterResult = struct( ...
    "schemaVersion", "thermoweave.simscape-run/v1", ...
    "status", buildReport.status, ...
    "message", buildReport.message, ...
    "build", buildReport, ...
    "result", [], ...
    "configuration", config);

if buildReport.status ~= "READY"
    return
end

modelPath = fullfile(options.ProjectRoot, buildReport.generatedModel);
if ~isfile(modelPath)
    adapterResult.status = "SKIPPED_MODEL_FILE_MISSING";
    adapterResult.message = "The generated-model manifest points to a missing file.";
    return
end

manifest = jsondecode(fileread(fullfile(options.ProjectRoot, "simscape", ...
    "models", "thermoweave-model-manifest.json")));
% Revalidate immediately before loading: neither the manifest nor the
% previously reported build READY state is authority to execute arbitrary SLX.
[approvedPath, modelDigest] = verifyGeneratedModelManifest( ...
    options.ProjectRoot, manifest, approvedSimscapeModelDigests());
if approvedPath ~= string(char(java.io.File(char(modelPath)).getCanonicalPath())) || ...
        modelDigest ~= buildReport.modelSha256
    error("thermoweave:simscape:ModelDigestMismatch", ...
        "The model changed between preflight and execution.");
end
modelPath = approvedPath;
adapterResult.modelSha256 = modelDigest;
nativeE9 = isfield(manifest, "outputContract") && ...
    strcmp(manifest.outputContract, "thermoweave.native-e9/v1");
if nativeE9
    config = thermoweave.config.loadScenario(config);
    reference = thermoweave.config.loadScenario(thermoweave.config.defaultConfig());
    candidate = config;
    candidate.simulation = reference.simulation;
    if ~isequaln(candidate, reference) || ~isequaln( ...
            rmfield(config.simulation, ["maxStep_s","relativeTolerance","absoluteTolerance"]), ...
            rmfield(reference.simulation, ["maxStep_s","relativeTolerance","absoluteTolerance"]))
        error("thermoweave:simscape:UnsupportedNativeE9Scenario", ...
            "The native E9 model supports the default scenario and solver refinement only.");
    end
end
[~, modelName] = fileparts(modelPath);
open_system(modelPath);
% A preloaded, dirty or different same-named model is not the hashed SLX.
loadedPath = string(char(java.io.File(char(get_param(modelName, ...
    "FileName"))).getCanonicalPath()));
if loadedPath ~= modelPath || strcmpi(get_param(modelName, "Dirty"), "on")
    error("thermoweave:simscape:LoadedModelMismatch", ...
        "Simulink did not load the unchanged approved SLX.");
end
in = Simulink.SimulationInput(modelName);
if isfield(config, "simulation") && isfield(config.simulation, "duration_s")
    in = in.setModelParameter("StopTime", string(config.simulation.duration_s));
end
if nativeE9
    in = in.setModelParameter("RelTol", string(config.simulation.relativeTolerance), ...
        "AbsTol", string(config.simulation.absoluteTolerance), ...
        "MaxStep", string(config.simulation.maxStep_s));
end
[finalPath, finalDigest] = verifyGeneratedModelManifest( ...
    options.ProjectRoot, manifest, approvedSimscapeModelDigests());
if finalPath ~= modelPath || finalDigest ~= modelDigest || ...
        strcmpi(get_param(modelName, "Dirty"), "on")
    error("thermoweave:simscape:ModelDigestMismatch", ...
        "The approved SLX changed before simulation.");
end
out = sim(in);
if nativeE9
    [raw, ledger] = decodeNativeE9(out, config);
    adapterResult.result = mapSimscapeResults(raw, config);
    adapterResult.result.energyLedger = ledger;
    adapterResult.result.metrics.integratedEnergyResidualNormalized = ledger.normalizedResidual;
else
    adapterResult.result = mapSimscapeResults(out, config);
end
adapterResult.status = "PASS";
adapterResult.message = "Simscape scenario executed and mapped.";
end
