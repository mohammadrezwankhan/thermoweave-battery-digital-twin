function receipt = packE9ParityReceipt(core, adapter, refinedCore, refinedAdapter, sourceSha)
%PACKE9PARITYRECEIPT Preserve four aligned E9 traces for independent review.
%   This is serialization and input validation only. It neither runs a
%   solver nor certifies numerical parity, licensing or scientific approval.

requireExecuted(adapter);
requireExecuted(refinedAdapter);
model = string(adapter.modelSha256);
if ~isscalar(model) || ismissing(model) || ...
        isempty(regexp(char(model), '^[0-9a-f]{64}$', 'once')) || ...
        ~isequal(model, string(refinedAdapter.modelSha256))
    error("thermoweave:e9:ModelMismatch", "E9 model digests must agree.");
end
sourceSha = string(sourceSha);
if ~isscalar(sourceSha) || ismissing(sourceSha) || ...
        isempty(regexp(char(sourceSha), '^[0-9a-f]{40}$', 'once'))
    error("thermoweave:e9:SourceIdentity", "An exact source SHA is required.");
end
release = string(version("-release"));
baseline = packPair(core, adapter, 0.25, release);
refined = packPair(refinedCore, refinedAdapter, 0.125, release);
receipt = struct("schemaVersion", "thermoweave.e9-parity/v1", ...
    "gitCommit", sourceSha, "matlabRelease", release, ...
    "modelSha256", model, "baseline", baseline, "refined", refined);
end

function requireExecuted(adapter)
if ~isstruct(adapter) || ~isscalar(adapter) || ...
        ~all(isfield(adapter, ["status","result","modelSha256","configuration"])) || ...
        ~isequal(string(adapter.status), "PASS") || isempty(adapter.result)
    error("thermoweave:e9:AdapterNotExecuted", ...
        "Both adapter executions must supply actual results.");
end
end

function pair = packPair(core, adapter, step, release)
coreTrace = packTrace(core, release);
adapterTrace = packTrace(adapter.result, release);
coreConfig = thermoweave.config.loadScenario(core.configuration);
adapterConfig = thermoweave.config.loadScenario(adapter.configuration);
resultConfig = thermoweave.config.loadScenario(adapter.result.configuration);
reference = thermoweave.config.loadScenario(thermoweave.config.defaultConfig());
reference.simulation = coreConfig.simulation;
if ~isequaln(coreConfig, adapterConfig) || ~isequaln(coreConfig, resultConfig) || ...
        ~isequaln(coreConfig, reference) || coreConfig.simulation.maxStep_s ~= step || ...
        coreConfig.simulation.duration_s ~= 600 || coreConfig.simulation.outputStep_s ~= 1
    error("thermoweave:e9:Configuration", ...
        "E9 traces must use the same native configuration and declared solver step.");
end
pair = struct("maxStep_s", step, "core", coreTrace, "simscape", adapterTrace);
end

function trace = packTrace(result, release)
if ~isstruct(result) || ~isscalar(result) || ...
        ~all(isfield(result, ["time_s","state","energyLedger","configuration","metadata"]))
    error("thermoweave:e9:Trace", "A complete result structure is required.");
end
if ~isnumeric(result.time_s) || ~isreal(result.time_s) || ...
        ~isequal(result.time_s(:), (0:600)')
    error("thermoweave:e9:TimeGrid", "Expected the complete one-second E9 output grid.");
end
if ~isstruct(result.metadata) || ~isfield(result.metadata, "matlabRelease") || ...
        ~isequal(string(result.metadata.matlabRelease), release)
    error("thermoweave:e9:RuntimeIdentity", "Trace MATLAB release does not match runtime.");
end
if ~isstruct(result.state) || ~all(isfield(result.state, ["temperature_K","soc"]))
    error("thermoweave:e9:Trace", "Temperature and SOC histories are required.");
end
temperature = result.state.temperature_K;
soc = result.state.soc;
if ~isnumeric(temperature) || ~isreal(temperature) || ...
        ~isequal(size(temperature), [601 12]) || ...
        any(~isfinite(temperature) | temperature <= 0, "all") || ...
        ~isnumeric(soc) || ~isreal(soc) || ~isequal(size(soc), [601 12]) || ...
        any(~isfinite(soc) | soc < 0 | soc > 1, "all")
    error("thermoweave:e9:Trace", "Invalid E9 temperature or SOC history.");
end
ledger = result.energyLedger;
fields = ["generatedHeat_J","ambientHeat_J","coolantHeat_J","externalHeat_J", ...
    "storedEnergyChange_J","normalizedResidual"];
if ~isstruct(ledger) || ~isscalar(ledger) || ~all(isfield(ledger, fields))
    error("thermoweave:e9:Ledger", "A complete signed energy ledger is required.");
end
for field = fields
    value = ledger.(field);
    if ~isnumeric(value) || ~isreal(value) || ~isscalar(value) || ~isfinite(value)
        error("thermoweave:e9:Ledger", "Energy ledger contains an invalid measurement.");
    end
end
if ledger.normalizedResidual < 0
    error("thermoweave:e9:Ledger", "Normalized residual cannot be negative.");
end
trace = struct("time_s", result.time_s, "temperature_K", temperature, ...
    "soc", soc, "energyLedger", ledger);
end
