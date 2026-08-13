function summary = runMonteCarloStudy(numberOfRuns)
%RUNMONTECARLOSTUDY Run a concise, seeded variability experiment.

arguments
    numberOfRuns (1, 1) double {mustBeInteger,mustBePositive} = 20
end

root = fileparts(fileparts(mfilename("fullpath")));
run(fullfile(root, "startup.m"));
peak = zeros(numberOfRuns, 1);
energy = zeros(numberOfRuns, 1);
seed = (6100:(6100 + numberOfRuns - 1))';
for index = 1:numberOfRuns
    config = thermoweave.config.defaultConfig();
    config.scenario.id = sprintf("E8-monte-carlo-%d", seed(index));
    config.simulation.duration_s = 120;
    config.simulation.outputStep_s = 2;
    config.simulation.seed = seed(index);
    config.variability.enabled = true;
    config.variability.seed = seed(index);
    result = thermoweave.simulate(config);
    peak(index) = result.metrics.peakTemperature_K;
    energy(index) = result.metrics.coolingEnergy_J;
end
summary = table(seed, peak, energy, ...
    'VariableNames', {'Seed', 'PeakTemperature_K', 'CoolingEnergy_J'});
disp(summary);
end
