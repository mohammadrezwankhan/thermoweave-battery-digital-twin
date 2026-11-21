function result = simulate(source,varargin)
%SIMULATE Portable graph electrothermal model with event-aligned integration.
cfg=thermoweave.config.loadScenario(source);
if nargin>1 && ~isempty(varargin{1}),cfg.simulation.seed=varargin{1};end
[cfg,varInfo]=thermoweave.uncertainty.applyVariability(cfg,cfg.simulation.seed);
topo=thermoweave.thermal.buildTopology(cfg.layout);
topo=applyEdgeVariability(topo,cfg);
N=topo.nodeCount; Zc=max(topo.zoneId);
t=(0:cfg.simulation.outputStep_s:cfg.simulation.duration_s)';
if t(end)<cfg.simulation.duration_s,t(end+1)=cfg.simulation.duration_s;end
Nt=numel(t);
T=zeros(Nt,N); S=zeros(Nt,N); BT=zeros(Nt,N); BH=zeros(Nt,N);
U=zeros(Nt,Zc); IHist=zeros(Nt,1); QHist=zeros(Nt,N);
CHist=zeros(Nt,1); residual=zeros(Nt,1);
methodHistory=repmat({''},Nt,1); objectiveHistory=NaN(Nt,1);
statusHistory=repmat({''},Nt,1);
events=declaredFaultEvents(cfg);
C=expand(cfg.cell.thermalCapacity_J_per_K,N);
y=[expand(cfg.cell.initialTemperature_K,N);expand(cfg.cell.initialSOC,N)];
state=struct('command',zeros(Zc,1));
cmd=zeros(Zc,1); method='uninitialized'; objective=NaN; status='';
opts=odeset('RelTol',cfg.simulation.relativeTolerance, ...
    'AbsTol',cfg.simulation.absoluteTolerance,'MaxStep',cfg.simulation.maxStep_s);

% Each controller sample and physical fault transition is a solver boundary,
% independent of how sparsely the user requests result samples.
period=cfg.controller.samplePeriod_s;
tickTimes=(0:floor(cfg.simulation.duration_s/period))'*period;
mesh=[t;tickTimes;cfg.simulation.duration_s];
if ~isempty(cfg.faults.events)
    for j=1:numel(cfg.faults.events)
        f=cfg.faults.events(j);
        mesh=[mesh;f.start_s;f.end_s]; %#ok<AGROW>
    end
end
profile=getField(cfg.electrical,'currentProfile',[]);
if isstruct(profile)&&~isempty(profile)&&isfield(profile,'time_s')
    mesh=[mesh;profile.time_s(:)];
end
mesh=unique(mesh(isfinite(mesh)&mesh>=0&mesh<=cfg.simulation.duration_s));
ledgerTerms_J=zeros(1,4); % generated, signed boundary, signed coolant, external

for k=1:numel(mesh)-1
    t0=mesh(k); t1=mesh(k+1);
    activationTime=(t0+t1)/2; % One-sided event state inside each interval.
    if any(abs(tickTimes-t0)<=16*eps(max(1,abs(t0))))
        sensed=applySensorFaults(y(1:N),cfg,t0,topo);
        ci=struct('temperature_K',sensed,'zoneId',topo.zoneId, ...
            'zoneWeights',ones(N,1), ...
            'referenceTemperature_K',cfg.controller.referenceTemperature_K, ...
            'elapsedStep_s',period);
        previousCommand=state.command(:);
        mode=lower(char(getField(cfg.controller,'mode','baseline')));
        switch mode
            case {'openloop','ol','none'}
                cmd=zeros(Zc,1); method='openloop_zero';
                objective=NaN; status='OPEN_LOOP';
            case {'advanced','ac'}
                [cmd,adv,state]=thermoweave.control.advancedController(ci,cfg,state);
                objective=adv.objective; status=adv.status;
                if adv.usedFallback
                    method='baseline_fallback';
                    events(end+1)=struct('type','controller_fallback', ...
                        'time_s',t0,'details',adv); %#ok<AGROW>
                else
                    method='advanced_quadratic_program';
                end
            otherwise
                [cmd,state]=thermoweave.control.baselineController(ci,cfg,state);
                method='baseline_bounded_controller';
                objective=NaN; status='BASELINE';
        end
        cmd=applyActuatorFaults(cmd,cfg,t0,previousCommand);
        state.command=cmd(:);
    end

    outputIndex=find(abs(t-t0)<=16*eps(max(1,abs(t0))),1);
    if ~isempty(outputIndex)
        T(outputIndex,:)=y(1:N)';S(outputIndex,:)=y(N+1:end)';
        U(outputIndex,:)=cmd(:)';
        [~,bd,qq,ii,cc,rr]=derivative(t0,y,cmd,activationTime);
        BT(outputIndex,:)=bd.temperature_K';
        BH(outputIndex,:)=bd.conductance_W_per_K';
        QHist(outputIndex,:)=qq';
        IHist(outputIndex)=mean(ii);
        CHist(outputIndex)=cc;residual(outputIndex)=rr;
        methodHistory{outputIndex}=method;
        objectiveHistory(outputIndex)=objective;
        statusHistory{outputIndex}=status;
    end

    rhs=@(tt,yy) derivative(tt,yy,cmd,activationTime);
    switch lower(char(cfg.simulation.solver))
        case 'ode45'
            [solverTimes,solverStates]=ode45(rhs,[t0 t1],y,opts);
        otherwise
            [solverTimes,solverStates]=ode15s(rhs,[t0 t1],y,opts);
    end
    % Independently integrate *physical power sources* at accepted ODE
    % states, then compare against the stored-energy change from endpoints.
    % This is NOT the former tautological same-RHS algebraic residual.
    powers=zeros(numel(solverTimes),4);
    for j=1:numel(solverTimes)
        temp=solverStates(j,1:N)';
        [~,b,q]=derivative(solverTimes(j),solverStates(j,:)',cmd,activationTime);
        powers(j,:)=[sum(q), ...
            sum(b.conductance_W_per_K.*(b.temperature_K-temp)), ...
            sum(b.qCool_W),sum(expand(cfg.thermal.externalHeat_W,N))];
    end
    ledgerTerms_J=ledgerTerms_J+trapz(solverTimes,powers,1);
    y=solverStates(end,:)';
    if any(y(N+1:end)<-1e-8|y(N+1:end)>1+1e-8)
        events(end+1)=struct('type','soc_bounds_violation', ...
            'time_s',t1,'details',[]); %#ok<AGROW>
    end
end
T(end,:)=y(1:N)'; S(end,:)=y(N+1:end)'; U(end,:)=cmd(:)';
[~,bd,qq,ii,cc,rr]=derivative(t(end),y,cmd,t(end));
BT(end,:)=bd.temperature_K';BH(end,:)=bd.conductance_W_per_K';
QHist(end,:)=qq';IHist(end)=mean(ii);
CHist(end)=cc;residual(end)=rr;
methodHistory{end}=method;objectiveHistory(end)=objective;statusHistory{end}=status;

meta=metadata(cfg,varInfo,t);
data=struct('time_s',t,'temperature_K',T,'soc',S, ...
    'boundaryTemperature_K',BT,'boundaryConductance_W_per_K',BH, ...
    'zoneCommand',U,'current_A',IHist,'heatGeneration_W',QHist, ...
    'coolingPower_W',CHist,'events',events);
result=thermoweave.results.makeResult(data,cfg,topo,meta);
% Preserve the result/v1 legacy residual; publish integrated metric separately.
result.energyResidualNormalized=max(abs(residual))/max(max(abs(QHist(:))),1e-9);
result.metrics.energyResidualNormalized=result.energyResidualNormalized;
storedEnergy_J=sum(C.*(y(1:N)-T(1,:)'));
netHeat_J=sum(ledgerTerms_J);
normalizer=max([abs(storedEnergy_J),sum(abs(ledgerTerms_J)),1e-9]);
integratedResidual=abs(storedEnergy_J-netHeat_J)/normalizer;
result.energyLedger=struct('generatedHeat_J',ledgerTerms_J(1), ...
    'ambientHeat_J',ledgerTerms_J(2), ...
    'coolantHeat_J',ledgerTerms_J(3), ...
    'externalHeat_J',ledgerTerms_J(4), ...
    'netHeat_J',netHeat_J,'storedEnergyChange_J',storedEnergy_J, ...
    'normalizedResidual',integratedResidual, ...
    'integrationRule','trapezoidal-on-accepted-solver-states');
result.metrics.integratedEnergyResidualNormalized=integratedResidual;
result.control.methodHistory=methodHistory;
result.control.objectiveHistory=objectiveHistory;
result.control.statusHistory=statusHistory;

function topo=applyEdgeVariability(topo,cfg)
if ~isfield(cfg.thermal,'edgeConductanceScale')||isempty(cfg.thermal.edgeConductanceScale),return;end
scale=cfg.thermal.edgeConductanceScale(:);
if numel(scale)~=topo.edgeCount,error('thermoweave:variability:Dimension','Edge variability must match topology edge count.');end
topo.edgeConductance_W_per_K=topo.edgeConductance_W_per_K.*scale;
topo.laplacian_W_per_K=topo.incidence'*diag(topo.edgeConductance_W_per_K)*topo.incidence;
end
function command=applyActuatorFaults(command,cfg,t,previousCommand)
if ~isfield(cfg.faults,'events')||isempty(cfg.faults.events),return;end
for index=1:numel(cfg.faults.events)
    event=cfg.faults.events(index);
    if strcmpi(char(getField(event,'type','')),'stuck_actuator')&& ...
            t>=getField(event,'start_s',0)&&t<=getField(event,'end_s',Inf)
        target=parseTarget(getField(event,'target',[]));
        if isempty(target),target=1:numel(command);end
        % A stuck actuator freezes the last applied command at fault onset;
        % magnitude remains legacy event metadata, not a forced setpoint.
        command(target)=previousCommand(target);
    end
end
end
function target=parseTarget(value)
if isnumeric(value),target=round(value);return;end
token=regexp(char(value),'\d+','match','once');target=str2double(token);
end
 function [dy,b,q,I,cp,res] = derivative(~,yy,cmd,activationTime)
  temp=yy(1:N); soc=yy(N+1:end);
  % Current profiles are piecewise constant, and their transitions are
  % explicitly included in the integration mesh.
  I=currentAt(cfg,activationTime,N); p=struct('ambientConductance_W_per_K',expand(cfg.thermal.ambientConductance_W_per_K,N),'edgeScale',ones(topo.edgeCount,1),'heatMultiplier',ones(N,1),'currentScale',ones(N,1),'coolantScale',ones(getField(cfg.boundary.coolant,'segments',4),1),'massFlow_kg_per_s',getField(cfg.boundary.coolant,'massFlow_kg_per_s',0.01)); [p,~]=thermoweave.uncertainty.applyFaults(cfg,activationTime,p); I=I.*p.currentScale; [q,~]=thermoweave.electrical.heatGeneration(temp,soc,I,cfg); q=q.*p.heatMultiplier; ccfg=cfg; ccfg.thermal.ambientConductance_W_per_K=p.ambientConductance_W_per_K; ccfg.boundary.coolant.massFlow_kg_per_s=p.massFlow_kg_per_s; b=thermoweave.coolant.evaluate(temp,ccfg,topo,cmd,activationTime);
  edgeG=topo.edgeConductance_W_per_K.*p.edgeScale; flow=accumarray([topo.edges(:,1);topo.edges(:,2)],[edgeG.*(temp(topo.edges(:,2))-temp(topo.edges(:,1)));edgeG.*(temp(topo.edges(:,1))-temp(topo.edges(:,2)))],[N 1]); C=expand(cfg.cell.thermalCapacity_J_per_K,N);
  externalHeat=expand(cfg.thermal.externalHeat_W,N);
  dT=(flow+b.conductance_W_per_K.*(b.temperature_K-temp)+q+b.qCool_W+externalHeat)./C;
  ds=thermoweave.electrical.socDerivative(soc,I,cfg); dy=[dT;ds]; cp=b.coolingPower_W;
  res=sum(C.*dT)-(sum(q)+sum(b.qCool_W)+sum(externalHeat)-sum(b.conductance_W_per_K.*(temp-b.temperature_K))+sum(flow));
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
m=struct('matlabRelease',version('-release'),'products',productManifest(),'seed',cfg.simulation.seed,'solver',cfg.simulation.solver,'tolerances',struct('relative',cfg.simulation.relativeTolerance,'absolute',cfg.simulation.absoluteTolerance,'maxStep_s',cfg.simulation.maxStep_s),'timestampUTC','','timestampPolicy','omitted-for-deterministic-core','scenarioHash',thermoweave.util.hashStruct(cfg),'scenarioCanonicalHash',thermoweave.util.hashCanonicalStruct(cfg),'scenarioCanonicalHashAlgorithm','thermoweave.canonical-json/v1','gitCommit','','variability',varInfo,'timeBase_s',t);
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
