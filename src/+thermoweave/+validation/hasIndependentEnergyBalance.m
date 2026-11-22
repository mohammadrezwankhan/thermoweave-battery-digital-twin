function accepted = hasIndependentEnergyBalance(result,relativeTolerance)
%HASINDEPENDENTENERGYBALANCE Validate signed power versus endpoint C*dT.
% Unlike the legacy same-RHS residual, this tests the independently
% integrated signed heat ledger against stored thermal energy reconstructed
% directly from temperatures and heat capacities. It is a numerical
% consistency gate for synthetic models, NOT physical-cell validation.
accepted=false;
if nargin<2 || isempty(relativeTolerance),relativeTolerance=1e-3;end
if ~isnumeric(relativeTolerance) || ~isscalar(relativeTolerance) || ~isreal(relativeTolerance) || ...
        ~isfinite(relativeTolerance) || relativeTolerance<0
    return
end
if ~isstruct(result) || ~isscalar(result) || ...
        ~all(isfield(result,{'energyLedger','configuration','state'})) || ...
        ~isfield(result.configuration,'cell') || ...
        ~isfield(result.configuration.cell,'thermalCapacity_J_per_K') || ...
        ~isfield(result.state,'temperature_K')
    return
end
temperature=result.state.temperature_K;
capacity=result.configuration.cell.thermalCapacity_J_per_K;
if ~isnumeric(temperature) || ~ismatrix(temperature) || ~isreal(temperature) || ...
        size(temperature,1)<2 || isempty(temperature) || ...
        any(~isfinite(temperature(:))) || ~isnumeric(capacity) || ...
        ~isreal(capacity) || ~isvector(capacity) || ...
        any(~isfinite(capacity(:))) || any(capacity(:)<=0)
    return
end
n=size(temperature,2);
if isscalar(capacity),capacity=repmat(capacity,n,1);else,capacity=capacity(:);end
if numel(capacity)~=n,return;end

ledger=result.energyLedger;
required={'generatedHeat_J','ambientHeat_J','coolantHeat_J', ...
    'externalHeat_J','netHeat_J','storedEnergyChange_J','normalizedResidual'};
if ~isstruct(ledger) || ~isscalar(ledger) || ~all(isfield(ledger,required))
    return
end
for k=1:numel(required)
    value=ledger.(required{k});
    if ~isnumeric(value) || ~isscalar(value) || ~isreal(value) || ~isfinite(value),return;end
end
signedParts=[ledger.generatedHeat_J,ledger.ambientHeat_J, ...
    ledger.coolantHeat_J,ledger.externalHeat_J];
stored=capacity'*(temperature(end,:)'-temperature(1,:)');
net=sum(signedParts);
scale=max([abs(stored),sum(abs(signedParts)),1e-9]);
residual=abs(stored-net)/scale;
% Reject contradictory, malformed, or self-reported zero-energy summaries.
consistencyAllowance=max(1e-8,1e-7*scale);
accepted=abs(ledger.netHeat_J-net)<=consistencyAllowance && ...
    abs(ledger.storedEnergyChange_J-stored)<=consistencyAllowance && ...
    abs(ledger.normalizedResidual-residual)<=1e-7 && ...
    residual<=relativeTolerance;
end
