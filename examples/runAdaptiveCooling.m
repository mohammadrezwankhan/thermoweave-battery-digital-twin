function comparison = runAdaptiveCooling()
%RUNADAPTIVECOOLING Compare open-loop and bounded baseline cooling.

root = fileparts(fileparts(mfilename("fullpath")));
run(fullfile(root, "startup.m"));
base = thermoweave.config.defaultConfig();
base.scenario.id = "E7-controller-comparison";
base.simulation.duration_s = 180;
base.simulation.outputStep_s = 2;
base.electrical.current_A = 18;
base.controller.referenceTemperature_K = 298.25;

openLoopConfig = base;
openLoopConfig.controller.mode = "openloop";
baselineConfig = base;
baselineConfig.controller.mode = "baseline";
openLoop = thermoweave.simulate(openLoopConfig);
baseline = thermoweave.simulate(baselineConfig);

comparison = table( ...
    ["open-loop"; "baseline"], ...
    [openLoop.metrics.peakTemperature_K; baseline.metrics.peakTemperature_K], ...
    [openLoop.metrics.coolingEnergy_J; baseline.metrics.coolingEnergy_J], ...
    'VariableNames', {'Controller', 'PeakTemperature_K', 'CoolingEnergy_J'});
disp(comparison);
end
