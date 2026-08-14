function figureHandle = render3DModule(result, options)
%RENDER3DMODULE Render a canonical ThermoWeave result as a 3-D cell lattice.
%   The figure uses one colored cuboid per graph node, an overlaid thermal
%   graph, labelled axes/colorbar, and a fixed camera so repeated renders are
%   directly comparable.  RESULT must be a thermoweave.result/v1 structure.

arguments
    result struct
    options.TimeIndex (1, 1) double {mustBeInteger, mustBePositive} = numel(result.time_s)
    options.Visible (1, 1) matlab.lang.OnOffSwitchState = "on"
end

if ~isfield(result, 'schemaVersion') || ...
        string(result.schemaVersion) ~= "thermoweave.result/v1"
    error('thermoweave:visualization:ResultSchema', ...
        'Expected a thermoweave.result/v1 structure.');
end
if ~isfield(result, 'topology') || ~isfield(result.topology, 'x_m') || ...
        ~isfield(result.topology, 'y_m')
    error('thermoweave:visualization:Topology', ...
        'Result topology must provide x_m and y_m coordinates.');
end

topology = result.topology;
index = min(options.TimeIndex, numel(result.time_s));
temperatureC = result.state.temperature_K(index, :)' - 273.15;
N = topology.nodeCount;
x = topology.x_m(:);
y = topology.y_m(:);
if isfield(topology, 'z_m')
    z = topology.z_m(:);
else
    z = zeros(N, 1);
end
if numel(x) ~= N || numel(y) ~= N || numel(z) ~= N
    error('thermoweave:visualization:Dimension', ...
        'Topology coordinates must match nodeCount.');
end

[dx, dy, dz] = cellPitch(topology, result);
halfSize = 0.45 * [dx dy dz];
[vertices, faces, faceColors] = cuboidMesh(x, y, z, halfSize, temperatureC);

figureHandle = figure('Color', [0.035 0.055 0.075], ...
    'Position', [100 100 1050 760], 'Visible', options.Visible, ...
    'Name', 'ThermoWeave 3-D module', 'NumberTitle', 'off');
axesHandle = axes('Parent', figureHandle, 'Color', [0.06 0.09 0.12], ...
    'NextPlot', 'add', 'Box', 'on', 'FontSize', 11, ...
    'XColor', [0.82 0.9 0.93], 'YColor', [0.82 0.9 0.93], ...
    'ZColor', [0.82 0.9 0.93], 'Tag', 'ThermoWeave3DModuleAxes');
patch('Parent', axesHandle, 'Vertices', vertices, 'Faces', faces, ...
    'FaceVertexCData', faceColors, 'FaceColor', 'flat', ...
    'EdgeColor', [0.82 0.91 0.95], 'LineWidth', 0.35, ...
    'DisplayName', 'Cell temperature');

if isfield(topology, 'edges') && ~isempty(topology.edges)
    edgePoints = nan(3 * size(topology.edges, 1), 3);
    for e = 1:size(topology.edges, 1)
        a = topology.edges(e, 1);
        b = topology.edges(e, 2);
        offset = 3 * (e - 1);
        edgePoints(offset + (1:3), :) = [x(a) y(a) z(a); x(b) y(b) z(b); nan nan nan];
    end
    line('Parent', axesHandle, 'XData', edgePoints(:, 1), ...
        'YData', edgePoints(:, 2), 'ZData', edgePoints(:, 3), ...
        'Color', [0.95 0.95 0.95], 'LineStyle', ':', ...
        'LineWidth', 0.45, 'HandleVisibility', 'off');
end

axis(axesHandle, 'equal');
grid(axesHandle, 'on');
xlabel(axesHandle, 'x (m)');
ylabel(axesHandle, 'y (m)');
zlabel(axesHandle, 'z (m)');
title(axesHandle, sprintf('3-D cell temperature at %.1f s', result.time_s(index)), ...
    'Color', [0.92 0.96 0.97]);
colorbarHandle = colorbar(axesHandle);
colorbarHandle.Label.String = 'Temperature (°C)';
colorbarHandle.Color = [0.82 0.9 0.93];
colormap(axesHandle, turbo(256));
view(axesHandle, [35 24]);
camproj(axesHandle, 'perspective');
set(axesHandle, 'Clipping', 'off');

end

function [dx, dy, dz] = cellPitch(topology, result)
layout = result.configuration.layout;
dx = getField(layout, 'pitchX_m', 1);
dy = getField(layout, 'pitchY_m', dx);
dz = getField(layout, 'pitchZ_m', min(dx, dy));
if isfield(topology, 'gridSize') && topology.gridSize(3) == 1
    dz = max(dz, 0.5 * min(dx, dy));
end
end

function [vertices, faces, colors] = cuboidMesh(x, y, z, halfSize, temperature)
N = numel(x);
vertices = zeros(8 * N, 3);
faces = zeros(6 * N, 4);
colors = zeros(6 * N, 1);
for i = 1:N
    base = 8 * (i - 1);
    vertices(base + (1:8), :) = [ ...
        x(i)-halfSize(1), y(i)-halfSize(2), z(i)-halfSize(3); ...
        x(i)+halfSize(1), y(i)-halfSize(2), z(i)-halfSize(3); ...
        x(i)+halfSize(1), y(i)+halfSize(2), z(i)-halfSize(3); ...
        x(i)-halfSize(1), y(i)+halfSize(2), z(i)-halfSize(3); ...
        x(i)-halfSize(1), y(i)-halfSize(2), z(i)+halfSize(3); ...
        x(i)+halfSize(1), y(i)-halfSize(2), z(i)+halfSize(3); ...
        x(i)+halfSize(1), y(i)+halfSize(2), z(i)+halfSize(3); ...
        x(i)-halfSize(1), y(i)+halfSize(2), z(i)+halfSize(3)];
    faces(6*(i-1)+(1:6), :) = base + [ ...
        1 2 3 4; 5 8 7 6; 1 5 6 2; ...
        2 6 7 3; 3 7 8 4; 4 8 5 1];
    colors(6*(i-1)+(1:6)) = temperature(i);
end
end

function value = getField(source, name, fallback)
if isfield(source, name) && ~isempty(source.(name))
    value = source.(name);
else
    value = fallback;
end
end
