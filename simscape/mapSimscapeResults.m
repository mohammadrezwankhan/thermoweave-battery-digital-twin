function result = mapSimscapeResults(raw, config)
%MAPSIMSCAPERESULTS Map adapter signals to thermoweave.result/v1.
%   A generated model must first expose transparent Nt-by-N arrays through
%   THERMOWEAVERAW; this mapper validates and completes the shared contract.

arguments
    raw
    config struct
end

if isa(raw, "Simulink.SimulationOutput")
    if ~raw.hasVariable("thermoweaveRaw")
        error("thermoweave:simscape:MissingCanonicalLog", ...
            "SimulationOutput must contain a thermoweaveRaw structure.");
    end
    raw = raw.get("thermoweaveRaw");
end
if ~isstruct(raw)
    error("thermoweave:simscape:RawType", ...
        "Adapter input must be a structure or SimulationOutput.");
end

config = thermoweave.config.loadScenario(config);
required = ["time_s", "temperature_K", "soc", "current_A"];
for name = required
    if ~isfield(raw, name)
        error("thermoweave:simscape:MissingSignal", ...
            "Missing required adapter signal '%s'.", name);
    end
end

time = raw.time_s(:);
temperature = raw.temperature_K;
soc = raw.soc;
nt = numel(time);
n = config.cell.count;
if isempty(time) || any(~isfinite(time)) || any(diff(time) <= 0)
    error("thermoweave:simscape:TimeBase", ...
        "time_s must be finite and strictly increasing.");
end
if ~isequal(size(temperature), [nt, n]) || ...
        ~isequal(size(soc), [nt, n]) || ...
        any(~isfinite(temperature), "all") || any(~isfinite(soc), "all")
    error("thermoweave:simscape:SignalDimensions", ...
        "Temperature and SOC must be finite Nt-by-N histories.");
end
current = optionalColumn(raw, "current_A", nt, true);
topology = thermoweave.thermal.buildTopology(config.layout);
zoneCommand = optionalHistory(raw, "zoneCommand", nt, ...
    max(topology.zoneId));
data = struct( ...
    "time_s", time, ...
    "temperature_K", temperature, ...
    "soc", soc, ...
    "boundaryTemperature_K", optionalMatrix(raw, ...
        "boundaryTemperature_K", nt, n, NaN), ...
    "boundaryConductance_W_per_K", optionalMatrix(raw, ...
        "boundaryConductance_W_per_K", nt, n, 0), ...
    "zoneCommand", zoneCommand, ...
    "current_A", current, ...
    "heatGeneration_W", optionalMatrix(raw, ...
        "heatGeneration_W", nt, n, NaN), ...
    "coolingPower_W", optionalColumn(raw, ...
        "coolingPowerProxy_W", nt, false), ...
    "events", optionalEvents(raw));
metadata = struct( ...
    "source", "simscape-adapter", ...
    "mappingStatus", "MAPPED_NOT_GROUND_TRUTH", ...
    "matlabRelease", string(version("-release")), ...
    "scenarioHash", thermoweave.util.hashStruct(config), ...
    "timestampUTC", "", ...
    "timestampPolicy", "omitted-for-deterministic-core");
result = thermoweave.results.makeResult(data, config, topology, metadata);
if ~isfield(raw, "energyResidualNormalized")
    error("thermoweave:simscape:MissingSignal", ...
        "Mapped results require energyResidualNormalized.");
end
residual = raw.energyResidualNormalized;
if ~isscalar(residual) || ~isfinite(residual) || residual < 0
    error("thermoweave:simscape:SignalDimensions", ...
        "energyResidualNormalized must be a nonnegative finite scalar.");
end
result.energyResidualNormalized = residual;
result.metrics = thermoweave.results.computeMetrics(result, config);
end

function value = optionalMatrix(raw, name, nt, n, fill)
if isfield(raw, name)
    value = raw.(name);
    if ~isequal(size(value), [nt, n])
        error("thermoweave:simscape:SignalDimensions", ...
            "Signal '%s' must be Nt-by-N.", name);
    end
else
    value = repmat(fill, nt, n);
end
end

function value = optionalColumn(raw, name, nt, required)
if isfield(raw, name)
    value = raw.(name)(:);
    if numel(value) ~= nt || any(~isfinite(value))
        error("thermoweave:simscape:SignalDimensions", ...
            "Signal '%s' must have Nt finite elements.", name);
    end
elseif required
    error("thermoweave:simscape:MissingSignal", ...
        "Missing required adapter signal '%s'.", name);
else
    value = zeros(nt, 1);
end
end

function value = optionalHistory(raw, name, nt, columns)
if isfield(raw, name)
    value = raw.(name);
    if ~isequal(size(value), [nt, columns]) || any(~isfinite(value), "all")
        error("thermoweave:simscape:SignalDimensions", ...
            "Signal '%s' must be Nt-by-%d and finite.", name, columns);
    end
else
    value = zeros(nt, columns);
end
end

function events = optionalEvents(raw)
if isfield(raw, "events")
    events = raw.events;
else
    events = struct("type", {}, "time_s", {}, "details", {});
end
end
