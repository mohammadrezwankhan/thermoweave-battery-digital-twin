function [cfg,info] = applyVariability(cfg,seed)
%APPLYVARIABILITY Apply seeded parameter dispersion without global RNG state.
if nargin<2 || isempty(seed), seed=getField(cfg.variability,'seed',getField(cfg.simulation,'seed',0)); end
info=struct('enabled',false,'seed',seed,'draws',struct());
if ~getField(cfg.variability,'enabled',false), return; end
rs=RandStream('mt19937ar','Seed',double(seed)); N=cfg.cell.count;
f=getField(cfg.variability,'uniformFraction',0.10);
cv=getField(cfg.variability,'R0CV',0.05);
R0=expand(getField(cfg.electrical,'R0_Ohm',0.008),N);
R0=R0.*exp(cv*randn(rs,N,1)-0.5*cv^2);
capacity=expand(getField(cfg.cell,'thermalCapacity_J_per_K',40.5),N) ...
    .*(1+f*(2*rand(rs,N,1)-1));
ambient=expand(getField(cfg.thermal,'ambientConductance_W_per_K',0.25),N) ...
    .*(1+f*(2*rand(rs,N,1)-1));
edgeScale=1+f*(2*rand(rs,edgeCount(cfg.layout),1)-1);
coolantScale=1+f*(2*rand(rs,N,1)-1);
cfg.electrical.R0_Ohm=R0;
cfg.cell.thermalCapacity_J_per_K=capacity;
cfg.thermal.ambientConductance_W_per_K=ambient;
cfg.thermal.edgeConductanceScale=edgeScale;
cfg.boundary.coolant.cellConductanceScale=coolantScale;
info.enabled=true;
info.draws=struct('R0_Ohm',R0,'capacity_J_per_K',capacity, ...
    'ambientConductance_W_per_K',ambient, ...
    'edgeConductanceScale',edgeScale, ...
    'coolantCellConductanceScale',coolantScale);
end
function count=edgeCount(layout)
if strcmpi(getField(layout,'type','rectangular'),'rectangular')
    count=layout.rows*(layout.columns-1)+layout.columns*(layout.rows-1);
else
    topology=thermoweave.thermal.buildTopology(layout); count=topology.edgeCount;
end
end
function x=expand(x,N),if isscalar(x),x=repmat(x,N,1);else,x=x(:);if numel(x)~=N,error('thermoweave:variability:Dimension','Variability dimension mismatch.');end,end,end
function v=getField(s,n,d),if isfield(s,n)&&~isempty(s.(n)),v=s.(n);else,v=d;end,end
