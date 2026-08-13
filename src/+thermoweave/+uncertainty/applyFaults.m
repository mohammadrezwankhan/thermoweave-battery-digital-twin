function [p,active] = applyFaults(cfg,t,p)
%APPLYFAULTS Apply declared event multipliers to runtime parameters.
active=struct('type',{},'target',{},'magnitude',{},'start_s',{},'end_s',{}); if ~isfield(cfg.faults,'events')||isempty(cfg.faults.events),return;end
for k=1:numel(cfg.faults.events)
 e=cfg.faults.events(k); t0=getField(e,'start_s',getField(e,'t_start_s',0)); t1=getField(e,'end_s',Inf); if t<t0||t>t1,continue;end
 typ=lower(char(getField(e,'type',''))); mag=getField(e,'magnitude',1); target=getField(e,'target',''); active(end+1)=struct('type',typ,'target',target,'magnitude',mag,'start_s',t0,'end_s',t1); %#ok<AGROW>
 switch typ
  case {'contact','contact_conductance'}, if isfield(p,'edgeScale'),p.edgeScale=applyTarget(p.edgeScale,target,mag);end
  case {'coolant_blockage','blocked_channel'}, if isfield(p,'coolantScale'),p.coolantScale=applyTarget(expandCount(p.coolantScale,getField(cfg.boundary.coolant,'segments',1)),target,max(0,mag));end
  case {'pump_loss','coolant_pump_loss'}, if isfield(p,'massFlow_kg_per_s'),p.massFlow_kg_per_s=p.massFlow_kg_per_s*max(0,mag);end
  case {'heat_multiplier','localized_heat'}, if isfield(p,'heatMultiplier'),p.heatMultiplier=applyTarget(expandLikeCells(p.heatMultiplier,p),target,mag);end
  case {'current_imbalance'}, if isfield(p,'currentScale'),p.currentScale=applyTarget(expandLikeCells(p.currentScale,p),target,mag);end
 end
end
end
function value=applyTarget(value,target,magnitude)
if isempty(target),value=value*magnitude;return;end
index=parseTarget(target); if isempty(index),return;end
if index<1||index>numel(value),error('thermoweave:fault:Target','Fault target is outside the runtime parameter range.');end
value(index)=value(index)*magnitude;
end
function value=expandLikeCells(value,p)
if isscalar(value)&&isfield(p,'ambientConductance_W_per_K')
    value=repmat(value,numel(p.ambientConductance_W_per_K),1);
end
end
function value=expandCount(value,count)
if isscalar(value),value=repmat(value,count,1);end
end
function index=parseTarget(target)
if isnumeric(target),index=round(target);return;end
token=regexp(char(target),'\d+','match','once'); if isempty(token),index=[];else,index=str2double(token);end
end
function v=getField(s,n,d),if isfield(s,n)&&~isempty(s.(n)),v=s.(n);else,v=d;end,end
