function dz = socDerivative(soc,I,cfg)
%SOCDERIVATIVE Coulomb counting with charge/discharge efficiencies.
soc=soc(:); I=I(:); N=numel(soc); Q=getField(cfg.electrical,'capacity_C',18000); if isscalar(Q),Q=repmat(Q,N,1);else,Q=Q(:);end
ed=getField(cfg.electrical,'dischargeEfficiency',1); ec=getField(cfg.electrical,'chargeEfficiency',1);
dz=-(max(I,0)./ed + min(I,0).*ec)./Q;
end
function v=getField(s,n,d),if isfield(s,n)&&~isempty(s.(n)),v=s.(n);else,v=d;end,end
