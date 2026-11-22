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
in = Simulink.SimulationInput(modelName);
if isfield(config, "simulation") && isfield(config.simulation, "duration_s")
    in = in.setModelParameter("StopTime", string(config.simulation.duration_s));
end
if nativeE9
    in = in.setModelParameter("RelTol", string(config.simulation.relativeTolerance), ...
        "AbsTol", string(config.simulation.absoluteTolerance), ...
        "MaxStep", string(config.simulation.maxStep_s));
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
