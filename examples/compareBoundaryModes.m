function summary = compareBoundaryModes()
%COMPAREBOUNDARYMODES Compare scalar, vector, zonal, and coolant scenarios.

root = fileparts(fileparts(mfilename("fullpath")));
run(fullfile(root, "startup.m"));
files = ["baseline.json", "vectorized-gradient.json", ...
    "nonuniform-cooling.json", "channel-restriction.json"];
summary = table('Size', [numel(files), 5], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'Scenario', 'Mode', 'PeakTemperature_K', ...
        'PeakSpread_K', 'CoolingEnergy_J'});
for index = 1:numel(files)
    result = thermoweave.simulate(fullfile(root, "config", files(index)));
    summary.Scenario(index) = string(result.configuration.scenario.id);
    summary.Mode(index) = string(result.configuration.boundary.mode);
    summary.PeakTemperature_K(index) = result.metrics.peakTemperature_K;
    summary.PeakSpread_K(index) = result.metrics.peakEdgeGradient_K;
    summary.CoolingEnergy_J(index) = result.metrics.coolingEnergy_J;
end
disp(summary);
end
