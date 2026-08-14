function cfg = validateConfig(cfg)
%VALIDATECONFIG Validate and canonicalise a ThermoWeave configuration.

required = {'schemaVersion','scenario','simulation','layout','cell', ...
    'thermal','electrical','boundary','controller','variability','faults','metrics'};
for index = 1:numel(required)
    if ~isfield(cfg, required{index}) || ~isstruct(cfg.(required{index})) && ...
            ~strcmp(required{index}, 'schemaVersion')
        error('thermoweave:config:MissingField', ...
            'Missing or invalid top-level field %s.', required{index});
    end
end
if string(cfg.schemaVersion) ~= "thermoweave.config/v1"
    error('thermoweave:config:Schema', ...
        'schemaVersion must be thermoweave.config/v1.');
end

layout = cfg.layout;
mustPositiveInteger(layout.rows, 'layout.rows');
mustPositiveInteger(layout.columns, 'layout.columns');
if ~isfield(layout, 'layers') || isempty(layout.layers)
    layout.layers = 1;
end
mustPositiveInteger(layout.layers, 'layout.layers');
cellCount = layout.rows * layout.columns * layout.layers;
if isfield(cfg.cell, 'count') && ~isempty(cfg.cell.count) && ...
        cfg.cell.count ~= cellCount
    error('thermoweave:config:Dimension', ...
        'cell.count must equal rows*columns.');
end
cfg.cell.count = cellCount;
if ~isfield(layout, 'zoneCount') || isempty(layout.zoneCount)
    layout.zoneCount = min(4, cellCount);
end
mustPositiveInteger(layout.zoneCount, 'layout.zoneCount');
if layout.zoneCount > cellCount
    error('thermoweave:config:Range', ...
        'layout.zoneCount must not exceed cell.count.');
end
if ~ismember(lower(string(layout.type)), ...
        ["rectangular", "staggered", "cuboid", "stacked-staggered"])
    error('thermoweave:config:Layout', ...
        ['layout.type must be rectangular, staggered, cuboid, ', ...
        'or stacked-staggered.']);
end
mustPositiveFinite(getField(layout, 'pitchX_m', 1), 'layout.pitchX_m');
mustPositiveFinite(getField(layout, 'pitchY_m', 1), 'layout.pitchY_m');
mustPositiveFinite(getField(layout, 'pitchZ_m', 1), 'layout.pitchZ_m');
mustPositiveFinite(getField(layout, 'gx_W_per_K', ...
    getField(layout, 'edgeConductance_W_per_K', 1)), ...
    'layout.gx_W_per_K');
mustPositiveFinite(getField(layout, 'gy_W_per_K', ...
    getField(layout, 'edgeConductance_W_per_K', 1)), ...
    'layout.gy_W_per_K');
mustPositiveFinite(getField(layout, 'gz_W_per_K', ...
    getField(layout, 'edgeConductance_W_per_K', 1)), ...
    'layout.gz_W_per_K');
cfg.layout = layout;

mustPositiveFinite(cfg.cell.initialTemperature_K, ...
    'cell.initialTemperature_K', cellCount);
mustRangeFinite(cfg.cell.initialSOC, 0, 1, ...
    'cell.initialSOC', cellCount);
mustPositiveFinite(cfg.cell.thermalCapacity_J_per_K, ...
    'cell.thermalCapacity_J_per_K', cellCount);
mustPositiveFinite(getField(cfg.cell, 'mass_kg', 1), 'cell.mass_kg', cellCount);
mustPositiveFinite(getField(cfg.cell, 'specificHeat_J_per_kgK', 1), ...
    'cell.specificHeat_J_per_kgK', cellCount);
mustPositiveFinite(getField(cfg.cell, 'area_m2', 1), ...
    'cell.area_m2', cellCount);

mustPositiveFinite(cfg.simulation.duration_s, 'simulation.duration_s');
mustPositiveFinite(cfg.simulation.outputStep_s, 'simulation.outputStep_s');
mustPositiveFinite(getField(cfg.simulation, 'maxStep_s', ...
    cfg.simulation.outputStep_s), 'simulation.maxStep_s');
mustPositiveFinite(cfg.simulation.relativeTolerance, ...
    'simulation.relativeTolerance');
mustPositiveFinite(cfg.simulation.absoluteTolerance, ...
    'simulation.absoluteTolerance');
if ~ismember(lower(string(cfg.simulation.solver)), ["ode15s", "ode45"])
    error('thermoweave:config:Solver', 'Solver must be ode15s or ode45.');
end
mustFinite(getField(cfg.simulation, 'seed', 0), 'simulation.seed');

mustPositiveFinite(cfg.thermal.ambientTemperature_K, ...
    'thermal.ambientTemperature_K', cellCount);
if isempty(cfg.thermal.ambientConductance_W_per_K)
    cfg.thermal.ambientConductance_W_per_K = 0.25;
end
mustNonnegativeFinite(cfg.thermal.ambientConductance_W_per_K, ...
    'thermal.ambientConductance_W_per_K', cellCount);
if ~isempty(getField(cfg.thermal, 'contactConductance_W_per_K', []))
    mustNonnegativeFinite(cfg.thermal.contactConductance_W_per_K, ...
        'thermal.contactConductance_W_per_K');
end
mustFinite(getField(cfg.thermal, 'externalHeat_W', 0), ...
    'thermal.externalHeat_W', cellCount);

mustFinite(cfg.electrical.current_A, 'electrical.current_A', cellCount);
profile = getField(cfg.electrical, 'currentProfile', []);
if isstruct(profile) && ~isempty(profile)
    if ~all(isfield(profile, {'time_s','current_A'})) || ...
            any(~isfinite(profile.time_s(:))) || ...
            any(diff(profile.time_s(:)) <= 0) || ...
            any(~isfinite(profile.current_A(:))) || ...
            ~(isscalar(profile.current_A) || ...
            numel(profile.current_A) == numel(profile.time_s))
        error('thermoweave:config:Profile', ...
            'currentProfile requires increasing finite time_s and matching finite current_A.');
    end
elseif ~isempty(profile) && (~isnumeric(profile) || any(~isfinite(profile(:))))
    error('thermoweave:config:Profile', ...
        'Numeric currentProfile values must be finite.');
end
mustPositiveFinite(cfg.electrical.capacity_Ah, 'electrical.capacity_Ah');
if cfg.electrical.capacity_C <= 0
    cfg.electrical.capacity_C = cfg.electrical.capacity_Ah * 3600;
end
mustPositiveFinite(cfg.electrical.capacity_C, 'electrical.capacity_C');
mustNonnegativeFinite(cfg.electrical.R0_Ohm, ...
    'electrical.R0_Ohm', cellCount);
mustFinite(getField(cfg.electrical, 'alphaT_per_K', 0), ...
    'electrical.alphaT_per_K');
mustFinite(getField(cfg.electrical, 'alphaSOC', 0), ...
    'electrical.alphaSOC');
mustPositiveFinite(cfg.electrical.temperatureReference_K, ...
    'electrical.temperatureReference_K');
temperatureRange = [200; 500; cfg.cell.initialTemperature_K(:); ...
    cfg.thermal.ambientTemperature_K(:); ...
    cfg.electrical.temperatureReference_K];
socRange = [0; 1];
resistanceFactor = 1 + cfg.electrical.alphaT_per_K .* ...
    (temperatureRange - cfg.electrical.temperatureReference_K) + ...
    cfg.electrical.alphaSOC .* (socRange' - 0.5);
if any(~isfinite(resistanceFactor), 'all') || any(resistanceFactor <= 0, 'all')
    error('thermoweave:config:Range', ...
        'Electrical resistance correction must remain positive over the declared envelope.');
end
mustRangeFinite(cfg.electrical.dischargeEfficiency, 0, 1, ...
    'electrical.dischargeEfficiency');
mustRangeFinite(cfg.electrical.chargeEfficiency, 0, 1, ...
    'electrical.chargeEfficiency');
if any(cfg.electrical.dischargeEfficiency(:) == 0) || ...
        any(cfg.electrical.chargeEfficiency(:) == 0)
    error('thermoweave:config:Range', ...
        'Electrical efficiencies must be greater than zero.');
end

mode = lower(string(cfg.boundary.mode));
if ~ismember(mode, ["scalar", "vector", "zonal", "coolant"])
    error('thermoweave:config:Boundary', ...
        'Boundary mode must be scalar, vector, zonal, or coolant.');
end
if mode == "scalar" || mode == "vector"
    mustPositiveFinite(cfg.boundary.temperature_K, ...
        'boundary.temperature_K', cellCount);
    mustNonnegativeFinite(cfg.boundary.conductance_W_per_K, ...
        'boundary.conductance_W_per_K', cellCount);
elseif mode == "zonal"
    mustPositiveFinite(cfg.boundary.zoneTemperature_K, ...
        'boundary.zoneTemperature_K', layout.zoneCount);
    mustNonnegativeFinite(cfg.boundary.zoneConductance_W_per_K, ...
        'boundary.zoneConductance_W_per_K', layout.zoneCount);
end
coolant = cfg.boundary.coolant;
mustPositiveInteger(coolant.segments, 'boundary.coolant.segments');
if coolant.segments > cellCount
    error('thermoweave:config:Range', ...
        'boundary.coolant.segments must not exceed cell.count.');
end
mustPositiveFinite(coolant.massFlow_kg_per_s, ...
    'boundary.coolant.massFlow_kg_per_s');
mustPositiveFinite(coolant.specificHeat_J_per_kgK, ...
    'boundary.coolant.specificHeat_J_per_kgK');
mustPositiveFinite(coolant.inletTemperature_K, ...
    'boundary.coolant.inletTemperature_K');
mustNonnegativeFinite(coolant.segmentConductance_W_per_K, ...
    'boundary.coolant.segmentConductance_W_per_K', coolant.segments);
segmentNodes = getField(coolant, 'segmentNodes', []);
if ~isempty(segmentNodes)
    validVector = isvector(segmentNodes) && numel(segmentNodes) == cellCount && ...
        all(isfinite(segmentNodes(:))) && all(segmentNodes(:) >= 1) && ...
        all(segmentNodes(:) <= coolant.segments) && ...
        all(segmentNodes(:) == floor(segmentNodes(:)));
    validMatrix = isequal(size(segmentNodes), [cellCount coolant.segments]) && ...
        all(isfinite(segmentNodes), 'all') && all(segmentNodes >= 0, 'all');
    if ~(validVector || validMatrix)
        error('thermoweave:config:Dimension', ...
            'coolant.segmentNodes must be N segment IDs or an N-by-K nonnegative map.');
    end
end

cfg.controller.zoneCount = layout.zoneCount;
if ~ismember(lower(string(cfg.controller.mode)), ...
        ["openloop", "ol", "none", "baseline", "advanced", "ac"])
    error('thermoweave:config:Controller', ...
        'Unsupported controller mode.');
end
if isempty(cfg.controller.Kp_per_K)
    cfg.controller.Kp_per_K = 0.2;
end
mustNonnegativeFinite(cfg.controller.Kp_per_K, ...
    'controller.Kp_per_K', layout.zoneCount);
mustNonnegativeFinite(cfg.controller.qMax_W, ...
    'controller.qMax_W', layout.zoneCount);
mustPositiveFinite(cfg.controller.samplePeriod_s, ...
    'controller.samplePeriod_s');
mustPositiveFinite(cfg.controller.referenceTemperature_K, ...
    'controller.referenceTemperature_K');
mustNonnegativeFinite(cfg.controller.deadband_K, ...
    'controller.deadband_K');
if any(isnan(cfg.controller.rateLimit_per_s(:))) || ...
        any(cfg.controller.rateLimit_per_s(:) < 0)
    error('thermoweave:config:Range', ...
        'controller.rateLimit_per_s must be nonnegative.');
end

mustNonnegativeFinite(cfg.variability.R0CV, 'variability.R0CV');
mustRangeFinite(cfg.variability.uniformFraction, 0, 1, ...
    'variability.uniformFraction');
mustFinite(cfg.variability.seed, 'variability.seed');
edgeCount = thermoweave.thermal.buildTopology(layout).edgeCount;
cfg = validateFaults(cfg, cellCount, layout.zoneCount, ...
    coolant.segments, edgeCount);

mustPositiveFinite(cfg.metrics.temperatureThreshold_K, ...
    'metrics.temperatureThreshold_K');
if any(isnan(cfg.metrics.edgeGradientLimit_K(:))) || ...
        any(cfg.metrics.edgeGradientLimit_K(:) < 0)
    error('thermoweave:config:Range', ...
        'metrics.edgeGradientLimit_K must be nonnegative.');
end
if numel(cfg.metrics.socBounds) ~= 2 || ...
        any(~isfinite(cfg.metrics.socBounds)) || ...
        cfg.metrics.socBounds(1) < 0 || cfg.metrics.socBounds(2) > 1 || ...
        cfg.metrics.socBounds(1) >= cfg.metrics.socBounds(2)
    error('thermoweave:config:Range', ...
        'metrics.socBounds must be increasing bounds inside [0,1].');
end
end

function cfg = validateFaults(cfg, cellCount, zoneCount, segmentCount, edgeCount)
if ~isfield(cfg.faults, 'events') || isempty(cfg.faults.events)
    cfg.faults.events = struct('type', {}, 'start_s', {}, 'end_s', {}, ...
        'target', {}, 'magnitude', {});
    return
end
known = ["contact", "contact_conductance", "coolant_blockage", ...
    "blocked_channel", "pump_loss", "coolant_pump_loss", ...
    "heat_multiplier", "localized_heat", "current_imbalance", ...
    "sensor_bias", "sensor_dropout", "stuck_actuator"];
for index = 1:numel(cfg.faults.events)
    event = cfg.faults.events(index);
    fields = {'type','start_s','end_s','target','magnitude'};
    if ~all(isfield(event, fields))
        error('thermoweave:config:Fault', ...
            'Each fault requires type, start_s, end_s, target, and magnitude.');
    end
    type = lower(string(event.type));
    if ~isscalar(type) || ~ismember(type, known)
        error('thermoweave:config:Fault', 'Unsupported fault type.');
    end
    mustFinite(event.start_s, 'fault.start_s');
    if ~isscalar(event.end_s) || isnan(event.end_s) || event.end_s == -Inf
        error('thermoweave:config:Fault', ...
            'fault.end_s must be finite or positive infinity.');
    end
    mustFinite(event.magnitude, 'fault.magnitude');
    if ~isscalar(event.start_s) || ~isscalar(event.end_s) || ...
            event.start_s < 0 || event.end_s < event.start_s
        error('thermoweave:config:Fault', ...
            'Fault time windows must satisfy 0 <= start_s <= end_s.');
    end
    target = parseTarget(event.target);
    if ~isempty(event.target) && isempty(target)
        error('thermoweave:config:Fault', ...
            'Fault target must be empty for global scope or contain an integer index.');
    end
    if ~isempty(target) && (target < 1 || target ~= floor(target))
        error('thermoweave:config:Fault', ...
            'Fault target must identify a positive integer index.');
    end
    limit = cellCount;
    if ismember(type, ["sensor_bias", "sensor_dropout", "stuck_actuator"])
        limit = zoneCount;
    elseif ismember(type, ["coolant_blockage", "blocked_channel"])
        limit = segmentCount;
    elseif ismember(type, ["contact", "contact_conductance"])
        limit = edgeCount;
    elseif ismember(type, ["pump_loss", "coolant_pump_loss"])
        limit = 1;
    end
    if ~isempty(target) && target > limit
        error('thermoweave:config:Fault', ...
            'Fault target exceeds the applicable model dimension.');
    end
    if event.magnitude < 0 && ismember(type, ...
            ["contact", "contact_conductance", "heat_multiplier", ...
            "localized_heat", "current_imbalance"])
        error('thermoweave:config:Fault', ...
            'Conductance, heat, and current multipliers must be nonnegative.');
    end
    if ismember(type, ["coolant_blockage", "blocked_channel"]) && ...
            (event.magnitude < 0 || event.magnitude > 1)
        error('thermoweave:config:Fault', ...
            'Coolant blockage magnitude must lie in [0,1].');
    end
    if ismember(type, ["pump_loss", "coolant_pump_loss"]) && ...
            (event.magnitude < 0 || event.magnitude > 1)
        error('thermoweave:config:Fault', ...
            'Pump-loss magnitude must be a remaining-flow factor in [0,1].');
    end
    if type == "stuck_actuator" && ...
            (event.magnitude < 0 || event.magnitude > 1)
        error('thermoweave:config:Fault', ...
            'Stuck-actuator magnitude must be a command in [0,1].');
    end
end
end

function target = parseTarget(value)
if isnumeric(value) && isscalar(value)
    target = value;
    return
end
token = regexp(char(string(value)), '\d+', 'match', 'once');
if isempty(token)
    target = [];
else
    target = str2double(token);
end
end

function mustPositiveInteger(value, name)
if ~isscalar(value) || ~isfinite(value) || value <= 0 || value ~= floor(value)
    error('thermoweave:config:Range', ...
        '%s must be a positive integer.', name);
end
end

function mustPositiveFinite(value, name, expected)
if nargin < 3, expected = []; end
mustSized(value, expected, name);
if any(~isfinite(value(:))) || any(value(:) <= 0)
    error('thermoweave:config:Range', '%s must be positive and finite.', name);
end
end

function mustNonnegativeFinite(value, name, expected)
if nargin < 3, expected = []; end
mustSized(value, expected, name);
if any(~isfinite(value(:))) || any(value(:) < 0)
    error('thermoweave:config:Range', ...
        '%s must be nonnegative and finite.', name);
end
end

function mustRangeFinite(value, lower, upper, name, expected)
if nargin < 5, expected = []; end
mustSized(value, expected, name);
if any(~isfinite(value(:))) || any(value(:) < lower) || ...
        any(value(:) > upper)
    error('thermoweave:config:Range', ...
        '%s must lie in [%g,%g].', name, lower, upper);
end
end

function mustFinite(value, name, expected)
if nargin < 3, expected = []; end
mustSized(value, expected, name);
if any(~isfinite(value(:)))
    error('thermoweave:config:Range', '%s must be finite.', name);
end
end

function mustSized(value, expected, name)
if isempty(value) || ~(isnumeric(value) || islogical(value))
    error('thermoweave:config:Range', '%s must be numeric and nonempty.', name);
end
if ~isempty(expected) && ~(isscalar(value) || numel(value) == expected)
    error('thermoweave:config:Dimension', ...
        '%s must be scalar or have %d elements.', name, expected);
end
end

function value = getField(source, name, fallback)
if isfield(source, name) && ~isempty(source.(name))
    value = source.(name);
else
    value = fallback;
end
end
