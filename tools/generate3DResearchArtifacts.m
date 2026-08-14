function evidence = generate3DResearchArtifacts()
%GENERATE3DRESEARCHARTIFACTS Generate traceable 3-D study data and figures.

root = fileparts(fileparts(mfilename("fullpath")));
run(fullfile(root, "startup.m"));

scenarioPath = fullfile(root, "config", "3d-intercell-study.json");
baseConfig = thermoweave.config.loadScenario(scenarioPath);
conductanceValues = [0.10 0.25 0.75];
caseIds = ["weak", "nominal", "strong"];
results = cell(numel(caseIds), 1);
records = repmat(struct(), numel(caseIds), 1);

for index = 1:numel(caseIds)
    config = baseConfig;
    config.scenario.id = "3d-intercell-" + caseIds(index);
    config.layout.gz_W_per_K = conductanceValues(index);
    result = thermoweave.simulate(config);
    results{index} = result;
    layerMeans = layerMeanHistory(result);
    records(index).caseId = caseIds(index);
    records(index).gz_W_per_K = conductanceValues(index);
    records(index).scenarioHash = string(result.metadata.scenarioHash);
    records(index).nodeCount = result.topology.nodeCount;
    records(index).edgeCount = result.topology.edgeCount;
    records(index).peakTemperature_K = result.metrics.peakTemperature_K;
    records(index).peakEdgeGradient_K = result.metrics.peakEdgeGradient_K;
    records(index).finalLayerMeanTemperature_K = layerMeans(end, :);
    records(index).finalLayerSpread_K = max(layerMeans(end, :)) - min(layerMeans(end, :));
    records(index).energyResidualNormalized = result.energyResidualNormalized;
end

artifactRoot = fullfile(root, "artifacts");
figureFolder = fullfile(artifactRoot, "figures");
dataFolder = fullfile(artifactRoot, "data");
reportFolder = fullfile(artifactRoot, "reports");
ensureFolders(figureFolder, dataFolder, reportFolder);

moduleFigure = thermoweave.visualization.render3DModule(results{2}, ...
    TimeIndex=numel(results{2}.time_s), Visible="off");
modulePath = fullfile(figureFolder, "3d-module-temperature.png");
exportgraphics(moduleFigure, modulePath, "Resolution", 220);
close(moduleFigure);

layerFigure = renderLayerComparison(results, caseIds, conductanceValues);
layerPath = fullfile(figureFolder, "3d-layer-response.png");
exportgraphics(layerFigure, layerPath, "Resolution", 220);
close(layerFigure);

tableRows = recordsTable(records);
csvPath = fullfile(dataFolder, "3d-study-results.csv");
writetable(tableRows, csvPath);

summary = struct( ...
    "schemaVersion", "thermoweave.study3d/v1", ...
    "studyType", "synthetic verification and sensitivity study", ...
    "sourceScenario", "config/3d-intercell-study.json", ...
    "sourceScenarioHash", thermoweave.util.hashStruct(baseConfig), ...
    "matlabRelease", string(version("-release")), ...
    "timestampPolicy", "omitted-for-deterministic-core", ...
    "modelBoundary", "Reduced-order lumped graph; no measured-cell validation; " + ...
        "not a safety or design-approval model.", ...
    "nodeOrdering", "r + (c-1)*rows + (layer-1)*rows*columns", ...
    "cases", records, ...
    "artifacts", struct( ...
        "moduleFigure", "artifacts/figures/3d-module-temperature.png", ...
        "layerFigure", "artifacts/figures/3d-layer-response.png", ...
        "table", "artifacts/data/3d-study-results.csv"));
reportPath = fullfile(reportFolder, "3d-study-summary.json");
writeJSON(reportPath, summary);

evidence = summary;
evidence.reportPath = string(reportPath);
evidence.moduleFigurePath = string(modulePath);
evidence.layerFigurePath = string(layerPath);
evidence.csvPath = string(csvPath);
end

function means = layerMeanHistory(result)
layerIds = unique(result.topology.layer(:), "stable");
means = zeros(numel(result.time_s), numel(layerIds));
for index = 1:numel(layerIds)
    means(:, index) = mean(result.state.temperature_K(:, ...
        result.topology.layer == layerIds(index)), 2);
end
end

function figureHandle = renderLayerComparison(results, caseIds, conductances)
colors = [0.09 0.43 0.67; 0.88 0.39 0.17; 0.22 0.63 0.42];
figureHandle = figure("Color", "white", "Position", [100 100 1120 740], ...
    "Visible", "off", "Name", "ThermoWeave 3-D layer response");
tiledlayout(2, 2, "Padding", "compact", "TileSpacing", "compact");
for index = 1:numel(results)
    result = results{index};
    means = layerMeanHistory(result) - 273.15;
    axisHandle = nexttile;
    plot(axisHandle, result.time_s, means, "LineWidth", 1.9);
    grid(axisHandle, "on");
    xlabel(axisHandle, "Time (s)");
    ylabel(axisHandle, "Layer mean (degC)");
    title(axisHandle, sprintf("%s through-layer coupling, g_z = %.2f W/K", ...
        caseIds(index), conductances(index)));
    legend(axisHandle, compose("Layer %d", 1:size(means, 2)), ...
        "Location", "northwest");
end
axisHandle = nexttile;
spreads = zeros(numel(results), 1);
for index = 1:numel(results)
    means = layerMeanHistory(results{index});
    spreads(index) = max(means(end, :)) - min(means(end, :));
end
bar(axisHandle, 1:numel(caseIds), spreads, "FaceColor", colors(2, :));
axisHandle.XTick = 1:numel(caseIds);
axisHandle.XTickLabel = caseIds;
grid(axisHandle, "on");
ylabel(axisHandle, "Final layer-mean spread (K)");
title(axisHandle, "Declared synthetic sensitivity outcome");
sgtitle("ThermoWeave-3D: traceable layer response", "FontWeight", "bold");
end

function output = recordsTable(records)
caseId = string({records.caseId})';
gz_W_per_K = [records.gz_W_per_K]';
nodeCount = [records.nodeCount]';
edgeCount = [records.edgeCount]';
peakTemperature_K = [records.peakTemperature_K]';
peakEdgeGradient_K = [records.peakEdgeGradient_K]';
finalLayerSpread_K = [records.finalLayerSpread_K]';
energyResidualNormalized = [records.energyResidualNormalized]';
scenarioHash = string({records.scenarioHash})';
output = table(caseId, gz_W_per_K, nodeCount, edgeCount, ...
    peakTemperature_K, peakEdgeGradient_K, finalLayerSpread_K, ...
    energyResidualNormalized, scenarioHash);
end

function ensureFolders(varargin)
for index = 1:nargin
    if ~isfolder(varargin{index})
        mkdir(varargin{index});
    end
end
end

function writeJSON(path, value)
file = fopen(path, "w");
if file < 0
    error("thermoweave:study3d:IO", "Unable to write %s.", path);
end
cleanup = onCleanup(@() fclose(file));
fwrite(file, jsonencode(value, PrettyPrint=true), "char");
end
