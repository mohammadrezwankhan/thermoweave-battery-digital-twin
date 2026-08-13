function result = simulate(source,varargin)
%SIMULATE Run the portable graph electrothermal ThermoWeave model.
cfg=thermoweave.config.loadScenario(source); if nargin>1 && ~isempty(varargin{1}),cfg.simulation.seed=varargin{1};end
[cfg,varInfo]=thermoweave.uncertainty.applyVariability(cfg,cfg.simulation.seed); topo=thermoweave.thermal.buildTopology(cfg.layout); topo=applyEdgeVariability(topo,cfg); N=topo.nodeCount; t=(0:cfg.simulation.outputStep_s:cfg.simulation.duration_s)';
if t(end)<cfg.simulation.duration_s, t(end+1)=cfg.simulation.duration_s;end; Nt=numel(t); Zc=max(topo.zoneId);
T=zeros(Nt,N); S=zeros(Nt,N); BT=zeros(Nt,N); BH=zeros(Nt,N); U=zeros(Nt,Zc); IHist=zeros(Nt,1); QHist=zeros(Nt,N); CHist=zeros(Nt,1); events=declaredFaultEvents(cfg);
T(1,:)=expand(cfg.cell.initialTemperature_K,N)'; S(1,:)=expand(cfg.cell.initialSOC,N)'; state=struct('command',zeros(Zc,1)); residual=zeros(Nt,1);
opts=odeset('RelTol',cfg.simulation.relativeTolerance,'AbsTol',cfg.simulation.absoluteTolerance,'MaxStep',cfg.simulation.maxStep_s);
for k=1:Nt-1
  t0=t(k); t1=t(k+1); y0=[T(k,:)';S(k,:)'];
  mode=lower(char(getField(cfg.controller,'mode','baseline'))); sensed=T(k,:)';
  sensed=applySensorFaults(sensed,cfg,t0,topo); ci=struct('temperature_K',sensed,'zoneId',topo.zoneId,'zoneWeights',ones(N,1),'referenceTemperature_K',cfg.controller.referenceTemperature_K,'elapsedStep_s',t1-t0);
  switch mode
   case {'openloop','ol','none'}, cmd=zeros(Zc,1);
   case {'advanced','ac'}, [cmd,adv,state]=thermoweave.control.advancedController(ci,cfg,state); if adv.usedFallback,events(end+1)=struct('type','controller_fallback','time_s',t0,'details',adv);end %#ok<AGROW>
   otherwise, [cmd,state]=thermoweave.control.baselineController(ci,cfg,state);
  end
  cmd=applyActuatorFaults(cmd,cfg,t0);
  U(k,:)=cmd(:)';
  rhs=@(tt,yy) derivative(tt,yy,cmd);
  switch lower(char(cfg.simulation.solver)), case 'ode45', [~,ys]=ode45(rhs,[t0 t1],y0,opts); otherwise, [~,ys]=ode15s(rhs,[t0 t1],y0,opts); end
  y1=ys(end,:)'; T(k+1,:)=y1(1:N)'; S(k+1,:)=y1(N+1:end)';
  if any(S(k+1,:)<-1e-8|S(k+1,:)>1+1e-8), events(end+1)=struct('type','soc_bounds_violation','time_s',t1,'details',[]);end %#ok<AGROW>
  [~,bd,qq,ii,cc,rr]=derivative(t1,y1,cmd); BT(k,:)=bd.temperature_K'; BH(k,:)=bd.conductance_W_per_K'; QHist(k,:)=qq'; IHist(k)=mean(ii); CHist(k)=cc; residual(k)=rr;
end

function topo=applyEdgeVariability(topo,cfg)
if ~isfield(cfg.thermal,'edgeConductanceScale')||isempty(cfg.thermal.edgeConductanceScale),return;end
scale=cfg.thermal.edgeConductanceScale(:);
if numel(scale)~=topo.edgeCount,error('thermoweave:variability:Dimension','Edge variability must match topology edge count.');end
topo.edgeConductance_W_per_K=topo.edgeConductance_W_per_K.*scale;
topo.laplacian_W_per_K=topo.incidence'*diag(topo.edgeConductance_W_per_K)*topo.incidence;
end
function command=applyActuatorFaults(command,cfg,t)
if ~isfield(cfg.faults,'events')||isempty(cfg.faults.events),return;end
for index=1:numel(cfg.faults.events)
    event=cfg.faults.events(index);
    if strcmpi(char(getField(event,'type','')),'stuck_actuator')&& ...
            t>=getField(event,'start_s',0)&&t<=getField(event,'end_s',Inf)
        target=parseTarget(getField(event,'target',[]));
        command(target)=max(0,min(1,getField(event,'magnitude',0)));
    end
end
end
function target=parseTarget(value)
if isnumeric(value),target=round(value);return;end
token=regexp(char(value),'\d+','match','once');target=str2double(token);
end
U(end,:)=U(max(1,end-1),:); [~,bd,qq,ii,cc,rr]=derivative(t(end),[T(end,:)';S(end,:)'],U(end,:)'); BT(end,:)=bd.temperature_K'; BH(end,:)=bd.conductance_W_per_K'; QHist(end,:)=qq'; IHist(end)=mean(ii); CHist(end)=cc; residual(end)=rr;
meta=metadata(cfg,varInfo,t); data=struct('time_s',t,'temperature_K',T,'soc',S,'boundaryTemperature_K',BT,'boundaryConductance_W_per_K',BH,'zoneCommand',U,'current_A',IHist,'heatGeneration_W',QHist,'coolingPower_W',CHist,'events',events);
result=thermoweave.results.makeResult(data,cfg,topo,meta); result.energyResidualNormalized=max(abs(residual))/max(max(abs(QHist(:))),1e-9); result.metrics.energyResidualNormalized=result.energyResidualNormalized;

 function [dy,b,q,I,cp,res] = derivative(tt,yy,cmd)
  temp=yy(1:N); soc=yy(N+1:end); I=currentAt(cfg,tt,N); p=struct('ambientConductance_W_per_K',expand(cfg.thermal.ambientConductance_W_per_K,N),'edgeScale',ones(topo.edgeCount,1),'heatMultiplier',ones(N,1),'currentScale',ones(N,1),'coolantScale',ones(getField(cfg.boundary.coolant,'segments',4),1),'massFlow_kg_per_s',getField(cfg.boundary.coolant,'massFlow_kg_per_s',0.01)); [p,~]=thermoweave.uncertainty.applyFaults(cfg,tt,p); I=I.*p.currentScale; [q,~]=thermoweave.electrical.heatGeneration(temp,soc,I,cfg); q=q.*p.heatMultiplier; ccfg=cfg; ccfg.thermal.ambientConductance_W_per_K=p.ambientConductance_W_per_K; ccfg.boundary.coolant.massFlow_kg_per_s=p.massFlow_kg_per_s; b=thermoweave.coolant.evaluate(temp,ccfg,topo,cmd,tt);
  edgeG=topo.edgeConductance_W_per_K.*p.edgeScale; flow=accumarray([topo.edges(:,1);topo.edges(:,2)],[edgeG.*(temp(topo.edges(:,2))-temp(topo.edges(:,1)));edgeG.*(temp(topo.edges(:,1))-temp(topo.edges(:,2)))],[N 1]); C=expand(cfg.cell.thermalCapacity_J_per_K,N); dT=(flow+b.conductance_W_per_K.*(b.temperature_K-temp)+q+b.qCool_W+expand(cfg.thermal.externalHeat_W,N))./C; ds=thermoweave.electrical.socDerivative(soc,I,cfg); dy=[dT;ds]; cp=b.coolingPower_W; res=sum(C.*dT)-(sum(q)+sum(b.qCool_W)-sum(b.conductance_W_per_K.*(temp-b.temperature_K))+sum(flow));
 end
end

function I=currentAt(cfg,tt,N)
v=getField(cfg.electrical,'current_A',5); p=getField(cfg.electrical,'currentProfile',[]);
if ~isempty(p)
 if isstruct(p),ts=p.time_s(:); vs=p.current_A; if isscalar(vs),vs=repmat(vs,numel(ts),1);end; v=interp1(ts,vs,tt,'previous','extrap'); elseif isscalar(p),v=p; else, v=interp1((0:numel(p)-1)',p(:),tt,'previous','extrap');end
end; I=expand(v,N);
end
function T=applySensorFaults(T,cfg,t,topo)
if ~isfield(cfg.faults,'events')||isempty(cfg.faults.events),return;end
 for k=1:numel(cfg.faults.events),e=cfg.faults.events(k);typ=lower(char(getField(e,'type','')));if t>=getField(e,'start_s',0)&&t<=getField(e,'end_s',Inf)&&any(strcmp(typ,{'sensor_bias','sensor_dropout'})),z=getField(e,'target',1);if ~isnumeric(z),token=regexp(char(z),'\d+','match','once');z=str2double(token);end;idx=topo.zoneId==z;if strcmp(typ,'sensor_bias'),T(idx)=T(idx)+getField(e,'magnitude',0);else,others=T(~idx);if isempty(others),others=T;end;T(idx)=mean(others(isfinite(others)));end,end,end
end
function events=declaredFaultEvents(cfg)
events=struct('type',{},'time_s',{},'details',{});
if ~isfield(cfg.faults,'events')||isempty(cfg.faults.events),return;end
for index=1:numel(cfg.faults.events)
    fault=cfg.faults.events(index);
    details=struct('target',getField(fault,'target',[]), ...
        'magnitude',getField(fault,'magnitude',1), ...
        'end_s',getField(fault,'end_s',Inf),'source','configuration');
    events(end+1)=struct('type',char(getField(fault,'type','fault')), ...
        'time_s',getField(fault,'start_s',0),'details',details); %#ok<AGROW>
end
end
function m=metadata(cfg,varInfo,t)
m=struct('matlabRelease',version('-release'),'products',productManifest(),'seed',cfg.simulation.seed,'solver',cfg.simulation.solver,'tolerances',struct('relative',cfg.simulation.relativeTolerance,'absolute',cfg.simulation.absoluteTolerance,'maxStep_s',cfg.simulation.maxStep_s),'timestampUTC','','timestampPolicy','omitted-for-deterministic-core','scenarioHash',thermoweave.util.hashStruct(cfg),'gitCommit','','variability',varInfo,'timeBase_s',t);
try
    [ok,out]=system('git rev-parse HEAD');
    if ok==0,m.gitCommit=strtrim(out);end
catch
end
function products=productManifest()
installed=ver; names={'MATLAB','Simulink','Simscape','Simscape Battery','Optimization Toolbox','Model Predictive Control Toolbox','MATLAB Test'};
products=struct('name',{},'version',{},'release',{});
for index=1:numel(names)
    match=find(strcmpi({installed.Name},names{index}),1);
    if ~isempty(match),products(end+1)=struct('name',installed(match).Name,'version',installed(match).Version,'release',installed(match).Release);end %#ok<AGROW>
end
end
end
function x=expand(x,N),if isscalar(x),x=repmat(x,N,1);else,x=x(:);if numel(x)~=N,error('thermoweave:simulation:Dimension','Vector dimension mismatch.');end,end,end
function v=getField(s,n,d),if isfield(s,n)&&~isempty(s.(n)),v=s.(n);else,v=d;end,end
