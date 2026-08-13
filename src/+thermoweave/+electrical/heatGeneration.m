function [q,details] = heatGeneration(T,soc,I,cfg)
%HEATGENERATION SOC/current/temperature-dependent Joule and entropic heat.
N=numel(T); T=T(:); soc=soc(:); I=expand(I,N);
R0=expand(getField(cfg.electrical,'R0_Ohm',0.008),N); alphaT=getField(cfg.electrical,'alphaT_per_K',0.003); alphaZ=getField(cfg.electrical,'alphaSOC',0.05); Tref=getField(cfg.electrical,'temperatureReference_K',298.15);
R=R0.*(1+alphaT.*(T-Tref)+alphaZ.*(1-soc)); R=max(R,eps); qJ=I.^2.*R; qE=zeros(N,1);
if getField(cfg.electrical,'entropicHeat',false), qE=-I.*T.*expand(getField(cfg.electrical,'dUoc_dT_V_per_K',0),N); end
q=qJ+qE; details=struct('resistance_Ohm',R,'joule_W',qJ,'entropic_W',qE,'current_A',I);
end
function x=expand(x,N),if isscalar(x),x=repmat(x,N,1);else,x=x(:);if numel(x)~=N,error('thermoweave:electrical:Dimension','Electrical vector dimension mismatch.');end,end,end
function v=getField(s,n,d),if isfield(s,n)&&~isempty(s.(n)),v=s.(n);else,v=d;end,end
