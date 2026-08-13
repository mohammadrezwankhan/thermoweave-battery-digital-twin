function [u,info,state] = advancedController(input,cfg,state)
%ADVANCEDCONTROLLER Reduced-horizon quadratic policy with safe fallback.
if nargin<3||isempty(state),state=struct('command',zeros(cfg.controller.zoneCount,1));end
info=struct('available',false,'usedFallback',true, ...
    'status','SKIPPED_MISSING_PRODUCT','objective',NaN,'message','', ...
    'method','reduced-horizon-quadratic','objectiveWeights',struct());
if exist('quadprog','file')==2
    info.available=true;
    try
        K=max(input.zoneId); ref=input.referenceTemperature_K;
        z=localMeans(input.temperature_K,input.zoneId); previous=state.command(:);
        qMax=expand(getField(cfg.controller,'qMax_W',25),K);
        capacity=zoneCapacity(cfg,input.zoneId,K);
        horizon=max(getField(cfg.controller.advanced,'horizon',20),eps);
        beta=qMax*horizon./capacity;
        lambdaU=max(getField(cfg.controller.advanced,'lambdaU',0.1),0);
        lambdaE=max(getField(cfg.controller.advanced,'lambdaE',0.01),0);
        lambdaG=max(getField(cfg.controller.advanced,'lambdaGradient',0.1),0);
        info.objectiveWeights=struct('tracking',1,'gradient',lambdaG, ...
            'movement',lambdaU,'coolingEffort',lambdaE);
        % Predicted zone temperature is z-beta.*u. This sign makes hotter
        % zones request more cooling and colder zones remain unactuated.
        betaMatrix=diag(beta); spreadProjector=eye(K)-ones(K)/K;
        zoneWeight=eye(K)+lambdaG*(spreadProjector'*spreadProjector);
        H=betaMatrix'*zoneWeight*betaMatrix+lambdaU*eye(K);
        effortScale=qMax/max(max(qMax),eps);
        f=-betaMatrix'*zoneWeight*(z-ref)-lambdaU*previous+ ...
            lambdaE*effortScale;
        lb=zeros(K,1); ub=ones(K,1);
        rate=expand(getField(cfg.controller,'rateLimit_per_s',Inf),K);
        elapsed=max(getField(input,'elapsedStep_s', ...
            getField(cfg.controller,'samplePeriod_s',1)),eps);
        delta=rate*elapsed;
        lb=max(lb,previous-delta); ub=min(ub,previous+delta);
        opts=optimoptions('quadprog','Display','off');
        [u,~,exitflag]=quadprog(H,f,[],[],[],[],lb,ub,previous,opts);
        if exitflag>0
            u=max(0,min(1,u)); info.usedFallback=false; info.status='OPTIMAL';
            info.objective=0.5*u'*H*u+f'*u; state.command=u;
            state.zoneMean_K=z; return
        end
        info.status='FALLBACK_QUADPROG_FAILURE';
    catch exception
        info.status='FALLBACK_QUADPROG_ERROR'; info.message=exception.message;
    end
end
[u,state]=thermoweave.control.baselineController(input,cfg,state);
end

function capacity=zoneCapacity(cfg,zoneId,K)
cellCapacity=expand(cfg.cell.thermalCapacity_J_per_K,numel(zoneId));
capacity=zeros(K,1);
for index=1:K
    capacity(index)=sum(cellCapacity(zoneId==index));
end
capacity=max(capacity,eps);
end
function z=localMeans(T,id),K=max(id);z=zeros(K,1);for k=1:K,idx=id==k;z(k)=mean(T(idx));end,end
function x=expand(x,N),if isscalar(x),x=repmat(x,N,1);else,x=x(:);if numel(x)~=N,error('thermoweave:control:Dimension','Advanced-controller dimension mismatch.');end,end,end
function v=getField(s,n,d),if isfield(s,n)&&~isempty(s.(n)),v=s.(n);else,v=d;end,end
