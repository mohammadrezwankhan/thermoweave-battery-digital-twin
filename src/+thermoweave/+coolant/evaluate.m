function b = evaluate(T,cfg,topo,zoneCommand,t)
%EVALUATE Evaluate scalar/vector/zonal/coolant boundary at a time/state.
N=numel(T); T=T(:); mode=lower(char(cfg.boundary.mode));
H=expand(cfg.thermal.ambientConductance_W_per_K,N); Ta=expand(cfg.thermal.ambientTemperature_K,N);
qCool=zeros(N,1); outlet=[]; coolantT=[]; flow=[]; Hcool=[];
switch mode
    case 'scalar'
        Ta=expand(getField(cfg.boundary,'temperature_K',Ta(1)),N); H=expand(getField(cfg.boundary,'conductance_W_per_K',H(1)),N);
    case 'vector'
        Ta=expand(getField(cfg.boundary,'temperature_K',Ta),N); H=expand(getField(cfg.boundary,'conductance_W_per_K',H),N);
    case 'zonal'
        zid=topo.zoneId; zc=max(zid); zT=expand(getField(cfg.boundary,'zoneTemperature_K',Ta(1)),zc); zH=expand(getField(cfg.boundary,'zoneConductance_W_per_K',H(1)),zc); Ta=zT(zid); H=zH(zid);
    case 'coolant'
        c=cfg.boundary.coolant; K=getField(c,'segments',4); flow=getField(c,'massFlow_kg_per_s',0.01); cp=getField(c,'specificHeat_J_per_kgK',3800); inlet=getField(c,'inletTemperature_K',Ta(1));
        Hcool=makeH(c,N,K,topo); Hcool=Hcool.*coolantScale(cfg,t,K); coolantT=zeros(K,1); prev=inlet;
        for k=1:K
            hk=Hcool(:,k); denom=max(flow*cp+sum(hk),eps); coolantT(k)=(flow*cp*prev+sum(hk.*T))/denom; qCool=qCool+hk.*(coolantT(k)-T); prev=coolantT(k);
        end
        outlet=prev; Ta=expand(getField(cfg.thermal,'ambientTemperature_K',inlet),N); H=expand(getField(cfg.thermal,'ambientConductance_W_per_K',0),N);
end
% Controller cooling is a prescribed zonal heat extraction proxy.
if nargin>=4 && ~isempty(zoneCommand) && any(zoneCommand)
    zid=topo.zoneId; zc=max(zid); qmax=expand(getField(cfg.controller,'qMax_W',25),zc); cmd=expand(zoneCommand,zc); qrem=qmax.*max(0,min(1,cmd));
    for z=1:zc
        idx=(zid==z); w=ones(sum(idx),1)/max(sum(idx),1); qCool(idx)=qCool(idx)-w*qrem(z);
    end
end
b=struct('temperature_K',Ta,'conductance_W_per_K',H,'qCool_W',qCool,'coolingPower_W',max(0,-sum(qCool)), ...
    'coolantTemperature_K',coolantT,'coolantOutletTemperature_K',outlet,'coolantFlow_kg_per_s',flow,'Hcool_W_per_K',Hcool,'mode',mode);
end
function H=makeH(c,N,K,topo)
H=zeros(N,K); nodes=getField(c,'segmentNodes',[]); h=getField(c,'segmentConductance_W_per_K',2);
if isscalar(h),h=repmat(h,K,1);else,h=h(:);if numel(h)~=K,error('thermoweave:boundary:Dimension','Coolant segment conductance must be scalar or K-by-1.');end,end
if isempty(nodes), zid=topo.zoneId; for i=1:N,segment=min(K,zid(i));H(i,segment)=h(segment);end
elseif isnumeric(nodes)
 if isvector(nodes) && numel(nodes)==N, for i=1:N,segment=min(K,max(1,round(nodes(i))));H(i,segment)=h(segment);end
 elseif isequal(size(nodes),[N K]), H=nodes.*h';
 end
end
scale=getField(c,'cellConductanceScale',ones(N,1));
if isscalar(scale),scale=repmat(scale,N,1);else,scale=scale(:);end
if numel(scale)~=N,error('thermoweave:boundary:Dimension','Coolant conductance variability must have N elements.');end
H=H.*scale;
end
function scale=coolantScale(cfg,t,segmentCount)
scale=ones(1,segmentCount); if ~isfield(cfg.faults,'events')||isempty(cfg.faults.events),return;end
for k=1:numel(cfg.faults.events)
    event=cfg.faults.events(k); type=char(getField(event,'type',''));
    if any(strcmpi(type,{'coolant_blockage','blocked_channel'})) && ...
            t>=getField(event,'start_s',0) && t<=getField(event,'end_s',Inf)
        target=parseTarget(getField(event,'target',[]));
        magnitude=getField(event,'magnitude',1);
        if isempty(target)
            scale=scale*magnitude;
        else
            scale(target)=scale(target)*magnitude;
        end
    end
end
end
function target=parseTarget(value)
if isempty(value),target=[];return;end
if isnumeric(value),target=round(value);return;end
token=regexp(char(value),'\d+','match','once');
if isempty(token),target=[];else,target=str2double(token);end
end
function x=expand(x,N),if isscalar(x),x=repmat(x,N,1);else,x=x(:);if numel(x)~=N,error('thermoweave:boundary:Dimension','Boundary vector dimension mismatch.');end,end,end
function v=getField(s,n,d),if isfield(s,n)&&~isempty(s.(n)),v=s.(n);else,v=d;end,end
