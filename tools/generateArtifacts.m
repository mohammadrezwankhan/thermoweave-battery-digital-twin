function evidence = generateArtifacts()
%GENERATEARTIFACTS Generate lightweight deterministic project evidence.

root = fileparts(fileparts(mfilename("fullpath")));
startupPath = fullfile(root, "startup.m");
run(startupPath);

result = runDemo();
figureHandle = thermoweave.visualization.renderFigure(result, Visible="off");
figurePath = fullfile(root, "artifacts", "figures", "thermal-overview.png");
exportgraphics(figureHandle, figurePath, "Resolution", 160);
close(figureHandle);

webManifest = exportWebData();
animationConfig = thermoweave.config.loadScenario(fullfile(root, "config", ...
    "vectorized-gradient.json"));
animationConfig.simulation.duration_s = 120;
animationConfig.simulation.outputStep_s = 4;
animationResult = thermoweave.simulate(animationConfig);
animationPath = fullfile(root, "artifacts", "animation", "thermal-field.gif");
animationManifest = thermoweave.visualization.exportAnimation( ...
    animationResult, animationPath, FrameCount=24, Delay_s=0.09);
verification = writeVerificationReport();
experiments = runExperimentSuite();
evidence = struct( ...
    "schemaVersion", "thermoweave.artifacts/v1", ...
    "figure", string(figurePath), ...
    "webData", webManifest, ...
    "animation", animationManifest, ...
    "verification", verification, ...
    "experiments", experiments, ...
    "peakTemperature_K", result.metrics.peakTemperature_K, ...
    "energyResidualNormalized", result.energyResidualNormalized, ...
    "matlabRelease", string(version("-release")));

reportPath = fullfile(root, "artifacts", "reports", "artifact-manifest.json");
portableEvidence = evidence;
portableEvidence.figure = "artifacts/figures/thermal-overview.png";
portableEvidence.webData.path = "artifacts/web-data/thermoweave-demo.json";
portableEvidence.animation.path = "artifacts/animation/thermal-field.gif";
portableEvidence.experiments.path = "artifacts/reports/experiment-summary.json";
file = fopen(reportPath, "w");
if file < 0
    error("thermoweave:artifacts:IO", "Unable to write artifact manifest.");
end
cleanup = onCleanup(@() fclose(file));
fwrite(file, jsonencode(portableEvidence), "char");
end
