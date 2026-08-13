function m = computeMetrics(result,cfg)
%COMPUTEMETRICS Compute canonical thermal, SOC, cooling and residual metrics.
T=result.state.temperature_K; Z=result.state.soc; t=result.time_s(:);
Tmax=max(T,[],2); Tmin=min(T,[],2); grad=zeros(size(T,1),1);
if isfield(result.topology,'edges') && ~isempty(result.topology.edges), e=result.topology.edges; grad=max(abs(T(:,e(:,1))-T(:,e(:,2))),[],2); end
thr=getField(cfg.metrics,'temperatureThreshold_K',318.15); timeHot=trapz(t,double(Tmax>thr));
if isfield(result,'signals') && isfield(result.signals,'coolingPowerProxy_W'), cool=result.signals.coolingPowerProxy_W(:); else,cool=zeros(size(t));end
if numel(t)>1, coolEnergy=trapz(t,max(cool,0)); else,coolEnergy=0;end
socSpread=max(Z,[],2)-min(Z,[],2);
socBounds=getField(cfg.metrics,'socBounds',[0 1]);
socViolation=Z(:)<socBounds(1)|Z(:)>socBounds(2);
edgeLimit=getField(cfg.metrics,'edgeGradientLimit_K',Inf);
m=struct('peakTemperature_K',max(Tmax),'minimumTemperature_K',min(Tmin),'meanTemperature_K',mean(T(:)), ...
 'temperature95thPercentile_K',percentile(T(:),95),'peakEdgeGradient_K',max(grad),'rmsEdgeGradient_K',sqrt(mean(grad.^2)), ...
 'timeAboveThreshold_s',timeHot,'socMean',mean(Z(:)),'socSpreadMax',max(socSpread),'socBoundsViolation',any(socViolation), ...
 'coolingEnergy_J',coolEnergy,'actuatorVariation',sum(abs(diff(result.control.zoneCommand,1,1)),'all'), ...
 'constraintViolations',sum(T(:)>getField(cfg.metrics,'temperatureThreshold_K',Inf))+sum(socViolation)+sum(grad>edgeLimit), ...
 'energyResidualNormalized',getField(result,'energyResidualNormalized',NaN));
end
function p=percentile(x,q)
x=sort(x(isfinite(x))); if isempty(x),p=NaN;return;end
u=1+(numel(x)-1)*q/100; lo=floor(u); hi=ceil(u); if lo==hi,p=x(lo);else,p=x(lo)+(u-lo)*(x(hi)-x(lo));end
end
function v=getField(s,n,d),if isfield(s,n)&&~isempty(s.(n)),v=s.(n);else,v=d;end,end
