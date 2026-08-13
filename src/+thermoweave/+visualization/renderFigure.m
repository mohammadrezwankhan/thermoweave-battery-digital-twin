function figureHandle = renderFigure(result, options)
%RENDERFIGURE Render a deterministic ThermoWeave result summary.

arguments
    result struct
    options.TimeIndex (1, 1) double {mustBeInteger,mustBePositive} = numel(result.time_s)
    options.Visible (1, 1) matlab.lang.OnOffSwitchState = "on"
end

index = min(options.TimeIndex, numel(result.time_s));
temperatureC = result.state.temperature_K - 273.15;
topology = result.topology;

figureHandle = figure( ...
    "Color", [0.035 0.055 0.075], ...
    "Position", [100 100 1200 680], ...
    "Visible", options.Visible, ...
    "Name", "ThermoWeave result");
layout = tiledlayout(figureHandle, 2, 2, "Padding", "compact", ...
    "TileSpacing", "compact");
title(layout, sprintf("%s — %s", string(result.configuration.scenario.id), ...
    string(result.configuration.boundary.mode)), "Color", [0.94 0.97 0.98]);

heatAxes = nexttile(layout, [2 1]);
scatter(heatAxes, topology.x_m, topology.y_m, 1250, ...
    temperatureC(index, :), "filled", "MarkerEdgeColor", [0.8 0.9 0.95]);
axis(heatAxes, "equal");
grid(heatAxes, "on");
xlabel(heatAxes, "x (m)");
ylabel(heatAxes, "y (m)");
title(heatAxes, sprintf("Cell temperature at %.0f s", result.time_s(index)));
colorBar = colorbar(heatAxes);
colorBar.Label.String = "Temperature (°C)";
colorBar.Color = [0.78 0.85 0.88];
colormap(heatAxes, turbo(256));

traceAxes = nexttile(layout);
plot(traceAxes, result.time_s, max(temperatureC, [], 2), ...
    "LineWidth", 2.2, "DisplayName", "Maximum");
hold(traceAxes, "on");
plot(traceAxes, result.time_s, mean(temperatureC, 2), ...
    "LineWidth", 1.8, "DisplayName", "Mean");
plot(traceAxes, result.time_s, min(temperatureC, [], 2), ...
    "LineWidth", 1.4, "DisplayName", "Minimum");
xline(traceAxes, result.time_s(index), ":", "DisplayName", "Frame");
ylabel(traceAxes, "Temperature (°C)");
xlabel(traceAxes, "Time (s)");
legend(traceAxes, "Location", "best");
grid(traceAxes, "on");
title(traceAxes, "Thermal envelope");

controlAxes = nexttile(layout);
spread = max(temperatureC, [], 2) - min(temperatureC, [], 2);
yyaxis(controlAxes, "left");
plot(controlAxes, result.time_s, spread, "LineWidth", 2.0);
ylabel(controlAxes, "Spread (K)");
yyaxis(controlAxes, "right");
if ~isempty(result.control.zoneCommand)
    plot(controlAxes, result.time_s, result.control.zoneCommand, ...
        "LineWidth", 1.2);
else
    plot(controlAxes, result.time_s, zeros(size(result.time_s)), ...
        "LineWidth", 1.2);
end
ylabel(controlAxes, "Zone command (0–1)");
xlabel(controlAxes, "Time (s)");
grid(controlAxes, "on");
title(controlAxes, "Spread and cooling command");

axesHandles = findall(figureHandle, "Type", "axes");
set(axesHandles, "Color", [0.06 0.09 0.12], ...
    "XColor", [0.78 0.85 0.88], "YColor", [0.78 0.85 0.88], ...
    "GridColor", [0.3 0.45 0.5]);
set(findall(figureHandle, "Type", "text"), "Color", [0.86 0.92 0.94]);
end
