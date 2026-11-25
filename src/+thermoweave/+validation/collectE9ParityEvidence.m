function [execution, evidence] = collectE9ParityEvidence(sourceSha, coreRunner, adapterRunner)
%COLLECTE9PARITYEVIDENCE Collect native E9 solver outputs without certifying parity.
%   Runners receive the same fixed scenario at baseline and refined steps.
%   A non-PASS adapter status is returned unchanged, without a parity receipt.
%   The independent release verifier, not this collector, evaluates parity.

arguments
    sourceSha (1,1) string
    coreRunner (1,1) function_handle
    adapterRunner (1,1) function_handle
end

baseline = thermoweave.config.defaultConfig();
refined = baseline;
refined.simulation.maxStep_s = 0.125;

execution = adapterRunner(baseline);
evidence = executionEvidence(execution);
if evidence.adapterStatus ~= "PASS"
    return
end

refinedExecution = adapterRunner(refined);
refinedEvidence = executionEvidence(refinedExecution);
if refinedEvidence.adapterStatus ~= "PASS"
    execution = refinedExecution;
    evidence = refinedEvidence;
    return
end

% Run the core only after both adapter executions have supplied PASS.
% No receipt is emitted if either core execution or packaging fails.
core = coreRunner(baseline);
refinedCore = coreRunner(refined);
evidence.numericalParity = thermoweave.validation.packE9ParityReceipt( ...
    core, execution, refinedCore, refinedExecution, sourceSha);
end

function evidence = executionEvidence(execution)
if ~isstruct(execution) || ~isscalar(execution) || ...
        ~all(isfield(execution, ["status","message"]))
    error("thermoweave:e9:AdapterExecution", "Adapter execution metadata is required.");
end
status = string(execution.status);
message = string(execution.message);
if ~isscalar(status) || ismissing(status) || strlength(status) == 0 || ...
        ~isscalar(message) || ismissing(message)
    error("thermoweave:e9:AdapterExecution", "Invalid adapter execution metadata.");
end
evidence = struct("adapterStatus", status, "message", message);
end
