function topo = buildTopology(layout)
%BUILDTOPOLOGY Build a deterministic 2-D or 3-D thermal graph lattice.
%   Layouts without LAYERS (or with LAYERS equal to one) retain the
%   historical rectangular/staggered node ordering.  Three-dimensional
%   layouts use the ordering r + (c-1)*rows + (l-1)*rows*columns and add
%   positive z-axis interfaces between adjacent layers.

if ~isfield(layout, 'rows') || ~isfield(layout, 'columns')
    error('thermoweave:topology:Dimensions', ...
        'rows and columns are required.');
end
nr = layout.rows;
nc = layout.columns;
nz = getField(layout, 'layers', 1);
if ~isscalar(nr) || ~isfinite(nr) || nr <= 0 || nr ~= floor(nr) || ...
        ~isscalar(nc) || ~isfinite(nc) || nc <= 0 || nc ~= floor(nc) || ...
        ~isscalar(nz) || ~isfinite(nz) || nz <= 0 || nz ~= floor(nz)
    error('thermoweave:topology:Dimensions', ...
        'rows, columns, and layers must be positive integers.');
end
N = nr * nc * nz;
px = getField(layout, 'pitchX_m', 1);
py = getField(layout, 'pitchY_m', 1);
pz = getField(layout, 'pitchZ_m', getField(layout, 'pitchY_m', 1));
if any(~isfinite([px py pz])) || any([px py pz] <= 0)
    error('thermoweave:topology:Pitch', ...
        'Lattice pitches must be positive and finite.');
end
type = lower(char(getField(layout, 'type', 'rectangular')));

row = zeros(N, 1);
col = zeros(N, 1);
layer = zeros(N, 1);
x = zeros(N, 1);
y = zeros(N, 1);
z = zeros(N, 1);
for l = 1:nz
    for c = 1:nc
        for r = 1:nr
            i = r + (c - 1) * nr + (l - 1) * nr * nc;
            row(i) = r;
            col(i) = c;
            layer(i) = l;
            offset = 0;
            if any(strcmp(type, {'staggered', 'stacked-staggered'})) && ...
                    mod(r, 2) == 0
                offset = 0.5;
            end
            % Stacked-staggered layers are deliberately co-registered in z;
            % this keeps each inter-layer interface deterministic and avoids
            % introducing diagonal thermal shortcuts.
            x(i) = ((c - 1) + offset) * px;
            y(i) = (r - 1) * py;
            z(i) = (l - 1) * pz;
        end
    end
end

edges = zeros(0, 2);
ge = zeros(0, 1);
axes = strings(0, 1);
gx = getField(layout, 'gx_W_per_K', ...
    getField(layout, 'edgeConductance_W_per_K', 1));
gy = getField(layout, 'gy_W_per_K', ...
    getField(layout, 'edgeConductance_W_per_K', gx));
gz = getField(layout, 'gz_W_per_K', ...
    getField(layout, 'edgeConductance_W_per_K', gx));
gStaggered = getField(layout, 'edgeConductance_W_per_K', 1);
if any(~isfinite([gx gy gz])) || any([gx gy gz] <= 0)
    error('thermoweave:topology:Conductance', ...
        'Edge conductances must be positive and finite.');
end

if any(strcmp(type, {'rectangular', 'cuboid'}))
    % Keep the legacy rectangular edge ordering exactly: x then y for
    % each node, followed by z interfaces for a 3-D lattice.
    for i = 1:N
        if col(i) < nc
            edges(end + 1, :) = [i i + nr]; %#ok<AGROW>
            ge(end + 1, 1) = gx; %#ok<AGROW>
            axes(end + 1, 1) = "x"; %#ok<AGROW>
        end
        if row(i) < nr
            edges(end + 1, :) = [i i + 1]; %#ok<AGROW>
            ge(end + 1, 1) = gy; %#ok<AGROW>
            axes(end + 1, 1) = "y"; %#ok<AGROW>
        end
        if layer(i) < nz
            edges(end + 1, :) = [i i + nr * nc]; %#ok<AGROW>
            ge(end + 1, 1) = gz; %#ok<AGROW>
            axes(end + 1, 1) = "z"; %#ok<AGROW>
        end
    end
elseif any(strcmp(type, {'staggered', 'stacked-staggered'}))
    % Preserve the legacy staggered neighbor rule within each layer and add
    % co-registered vertical interfaces.  Pair iteration is deterministic.
    tol = getField(layout, 'neighborTolerance_m', 1.25 * max(px, py));
    for l = 1:nz
        first = (l - 1) * nr * nc + 1;
        last = l * nr * nc;
        for i = first:last
            for j = i + 1:last
                dr = abs(y(i) - y(j));
                dx = abs(x(i) - x(j));
                d = hypot(dx, dr);
                sameRow = row(i) == row(j) && abs(col(i) - col(j)) == 1;
                adjacent = abs(row(i) - row(j)) == 1 && d <= tol;
                if sameRow || adjacent
                    edges(end + 1, :) = [i j]; %#ok<AGROW>
                    ge(end + 1, 1) = gStaggered * max(0.25, ...
                        min(4, max(px, py) / max(d, eps))); %#ok<AGROW>
                    if sameRow
                        axes(end + 1, 1) = "x"; %#ok<AGROW>
                    else
                        axes(end + 1, 1) = "y"; %#ok<AGROW>
                    end
                end
            end
        end
    end
    for i = 1:N
        if layer(i) < nz
            edges(end + 1, :) = [i i + nr * nc]; %#ok<AGROW>
            ge(end + 1, 1) = gz; %#ok<AGROW>
            axes(end + 1, 1) = "z"; %#ok<AGROW>
        end
    end
else
    error('thermoweave:topology:Layout', ...
        'layout.type must be rectangular, staggered, cuboid, or stacked-staggered.');
end

if any(~isfinite(ge)) || any(ge <= 0)
    error('thermoweave:topology:Conductance', ...
        'Edge conductances must be positive and finite.');
end

zoneCount = getField(layout, 'zoneCount', min(4, N));
if ~isscalar(zoneCount) || ~isfinite(zoneCount) || zoneCount <= 0 || ...
        zoneCount ~= floor(zoneCount) || zoneCount > N
    error('thermoweave:topology:Zones', ...
        'zoneCount must be a positive integer no greater than node count.');
end
zoneId = min(zoneCount, ceil((1:N)' / (N / zoneCount)));
B = zeros(size(edges, 1), N);
for e = 1:size(edges, 1)
    B(e, edges(e, 1)) = 1;
    B(e, edges(e, 2)) = -1;
end

surfaceMasks = struct( ...
    'xMin', col == 1, 'xMax', col == nc, ...
    'yMin', row == 1, 'yMax', row == nr, ...
    'zMin', layer == 1, 'zMax', layer == nz);
topo = struct('nodeId', (1:N)', 'row', row, 'column', col, ...
    'layer', layer, 'x_m', x, 'y_m', y, 'z_m', z, ...
    'gridSize', [nr nc nz], 'edges', edges, ...
    'edgeConductance_W_per_K', ge, 'edgeAxis', axes, ...
    'edgeAxisLabels', axes, 'incidence', B, ...
    'laplacian_W_per_K', B' * diag(ge) * B, 'zoneId', zoneId, ...
    'channelOrder', (1:N)', 'surfaceMasks', surfaceMasks, ...
    'surfaceMask', surfaceMasks, ...
    'surfaceMask_xMin', surfaceMasks.xMin, ...
    'surfaceMask_xMax', surfaceMasks.xMax, ...
    'surfaceMask_yMin', surfaceMasks.yMin, ...
    'surfaceMask_yMax', surfaceMasks.yMax, ...
    'surfaceMask_zMin', surfaceMasks.zMin, ...
    'surfaceMask_zMax', surfaceMasks.zMax, ...
    'nodeCount', N, 'edgeCount', size(edges, 1));
end

function value = getField(source, name, fallback)
if isfield(source, name) && ~isempty(source.(name))
    value = source.(name);
else
    value = fallback;
end
end
