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

[~, modelName] = fileparts(modelPath);
open_system(modelPath);
in = Simulink.SimulationInput(modelName);
if isfield(config, "simulation") && isfield(config.simulation, "duration_s")
    in = in.setModelParameter("StopTime", string(config.simulation.duration_s));
end
out = sim(in);
adapterResult.result = mapSimscapeResults(out, config);
adapterResult.status = "PASS";
adapterResult.message = "Simscape scenario executed and mapped.";
end
