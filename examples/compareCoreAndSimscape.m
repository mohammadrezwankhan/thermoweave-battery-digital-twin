%% Compare core and optional Simscape adapter
% This comparison treats neither implementation as ground truth. It records
% an explicit skip when products, policy, or a generated model are absent.

projectRoot = fileparts(fileparts(mfilename("fullpath")));
run(fullfile(projectRoot, "startup.m"));
config = thermoweave.config.loadScenario(fullfile(projectRoot, "config", "baseline.json"));
coreResult = thermoweave.thermal.simulate(config);
adapter = runSimscapeScenario(config, ProjectRoot=string(projectRoot));

fprintf("Core peak temperature: %.3f K\n", coreResult.metrics.peakTemperature_K);
fprintf("Simscape adapter status: %s\n", adapter.status);
if adapter.status == "PASS"
    fprintf("Comparison available; interpret structural differences documented in docs/validation.md.\n");
else
    fprintf("Comparison not executed: %s\n", adapter.message);
end
