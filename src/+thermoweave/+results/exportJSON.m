function manifest = exportJSON(result,path,varargin)
%EXPORTJSON Deterministically export a result and a compact manifest hash.
if nargin<2||isempty(path), error('thermoweave:results:Path','An output path is required.'); end
if ~isfolder(fileparts(path)) && ~isempty(fileparts(path)), mkdir(fileparts(path)); end
compact=result; if ~isempty(varargin), compact=downsample(compact,varargin{1}); end
txt=jsonencode(compact); fid=fopen(path,'w'); if fid<0,error('thermoweave:results:IO','Cannot open output file.');end
fwrite(fid,txt,'char'); fclose(fid); manifest=struct('path',path,'sha256',thermoweave.util.hashText(txt),'bytes',numel(txt));
end
function r=downsample(r,step)
if ~isnumeric(step)||~isscalar(step)||~isfinite(step)||step<1||step~=floor(step)
    error('thermoweave:results:Downsample','Downsample stride must be a positive integer.');
end
if isempty(r.time_s)
    error('thermoweave:results:Downsample','Cannot downsample an empty result.');
end
sourceSampleCount=numel(r.time_s);
idx=1:step:sourceSampleCount;
if idx(end)~=sourceSampleCount,idx(end+1)=sourceSampleCount;end
r.time_s=r.time_s(idx);
if isfield(r,'metadata')
    r.metadata.sourceSampleCount=sourceSampleCount;
    if isfield(r.metadata,'timeBase_s'),r.metadata.timeBase_s=r.time_s;end
end
f={'temperature_K','soc'}; for k=1:numel(f),r.state.(f{k})=r.state.(f{k})(idx,:);end
r.boundary.temperature_K=r.boundary.temperature_K(idx,:);r.boundary.conductance_W_per_K=r.boundary.conductance_W_per_K(idx,:);r.control.zoneCommand=r.control.zoneCommand(idx,:);r.signals.current_A=r.signals.current_A(idx);r.signals.heatGeneration_W=r.signals.heatGeneration_W(idx,:);r.signals.coolingPowerProxy_W=r.signals.coolingPowerProxy_W(idx);
end
