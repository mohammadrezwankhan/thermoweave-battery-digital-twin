function manifest = exportAnimation(result, path, options)
%EXPORTANIMATION Export a compact animated GIF from a canonical result.

arguments
    result struct
    path (1, 1) string
    options.FrameCount (1, 1) double {mustBeInteger,mustBePositive} = 30
    options.Delay_s (1, 1) double {mustBePositive} = 0.08
end

if string(result.schemaVersion) ~= "thermoweave.result/v1"
    error("thermoweave:visualization:ResultSchema", ...
        "Animation input must use thermoweave.result/v1.");
end
folder = fileparts(path);
if ~isfolder(folder)
    mkdir(folder);
end

indices = unique(round(linspace(1, numel(result.time_s), ...
    min(options.FrameCount, numel(result.time_s)))));
temperatureC = result.state.temperature_K - 273.15;
minimum = min(temperatureC, [], "all");
maximum = max(temperatureC, [], "all");
if maximum <= minimum
    maximum = minimum + 1;
end

figureHandle = figure("Visible", "off", "Color", [0.035 0.055 0.075], ...
    "Position", [100 100 720 520]);
cleanupFigure = onCleanup(@() close(figureHandle));
axesHandle = axes(figureHandle, "Color", [0.06 0.09 0.12], ...
    "XColor", [0.78 0.85 0.88], "YColor", [0.78 0.85 0.88], ...
    "Position", [0.12 0.14 0.7 0.74]);
temporaryImage = string(tempname) + ".png";
cleanupImage = onCleanup(@() deleteIfPresent(temporaryImage));

for frame = 1:numel(indices)
    index = indices(frame);
    scatter(axesHandle, result.topology.x_m, result.topology.y_m, 1100, ...
        temperatureC(index, :), "filled", ...
        "MarkerEdgeColor", [0.85 0.95 1]);
    axis(axesHandle, "equal");
    axesHandle.Color = [0.06 0.09 0.12];
    axesHandle.XColor = [0.78 0.85 0.88];
    axesHandle.YColor = [0.78 0.85 0.88];
    axesHandle.CLim = [minimum maximum];
    axesHandle.XLim = [min(result.topology.x_m) - 0.015, ...
        max(result.topology.x_m) + 0.015];
    axesHandle.YLim = [min(result.topology.y_m) - 0.015, ...
        max(result.topology.y_m) + 0.015];
    grid(axesHandle, "on");
    colormap(axesHandle, turbo(256));
    title(axesHandle, sprintf("ThermoWeave — %.0f s", result.time_s(index)), ...
        "Color", [0.9 0.96 0.97]);
    xlabel(axesHandle, "x (m)");
    ylabel(axesHandle, "y (m)");
    colorBar = colorbar(axesHandle);
    colorBar.Label.String = "Temperature (°C)";
    colorBar.Color = [0.78 0.85 0.88];
    exportgraphics(figureHandle, temporaryImage, "Resolution", 100, ...
        "BackgroundColor", [0.035 0.055 0.075]);
    rgb = imread(temporaryImage);
    [indexed, map] = rgb2ind(rgb, 256);
    if frame == 1
        imwrite(indexed, map, path, "gif", "LoopCount", Inf, ...
            "DelayTime", options.Delay_s);
    else
        imwrite(indexed, map, path, "gif", "WriteMode", "append", ...
            "DelayTime", options.Delay_s);
    end
end

manifest = struct("path", path, "sha256", ...
    thermoweave.util.hashFile(path), "frames", numel(indices), ...
    "delay_s", options.Delay_s);
end

function deleteIfPresent(path)
if isfile(path)
    delete(path);
end
end
