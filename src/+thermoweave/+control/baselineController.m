function [u,state] = baselineController(input,cfg,state)
%BASELINECONTROLLER Bounded, deterministic, rate-limited zonal controller.
if nargin<3||isempty(state), state=struct('command',zeros(cfg.controller.zoneCount,1)); end
z=zoneMeans(input.temperature_K,input.zoneId,input.zoneWeights);
ref=getField(input,'referenceTemperature_K',cfg.controller.referenceTemperature_K);
kp=expand(getField(cfg.controller,'Kp_per_K',0.2),numel(z));
q=max(0,kp.*(z-ref)-getField(cfg.controller,'deadband_K',0)); u=max(0,min(1,q));
dt=max(getField(input,'elapsedStep_s',getField(cfg.controller,'samplePeriod_s',1)),eps); rate=expand(getField(cfg.controller,'rateLimit_per_s',Inf),numel(z));
d=rate*dt; u=max(state.command-d,min(state.command+d,u));
u=max(0,min(1,u)); state.command=u(:); state.zoneMean_K=z(:);
end
function z=zoneMeans(T,zid,w)
T=T(:); zid=zid(:); K=max(zid); z=zeros(K,1); if nargin<3||isempty(w),w=ones(size(T));end
for k=1:K,idx=zid==k;ww=w(idx);z(k)=sum(ww(:).*T(idx))/max(sum(ww),eps);end
end
function x=expand(x,N),if isscalar(x),x=repmat(x,N,1);else,x=x(:);if numel(x)~=N,error('thermoweave:control:Dimension','Controller gain dimension mismatch.');end,end,end
function v=getField(s,n,d),if isfield(s,n)&&~isempty(s.(n)),v=s.(n);else,v=d;end,end
