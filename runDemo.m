function result = runDemo(varargin)
%RUNDEMO Execute a deterministic compact ThermoWeave demonstration.
startup();
source=[]; exportPath='';
if nargin>=1 && ~(ischar(varargin{1})||isstring(varargin{1})), source=varargin{1};
elseif nargin>=1, source=varargin{1}; end
if nargin>=2, exportPath=char(varargin{2}); end
if isempty(source), cfg=thermoweave.config.defaultConfig(); cfg.simulation.duration_s=30; cfg.simulation.outputStep_s=1; result=thermoweave.simulate(cfg); else, result=thermoweave.simulate(source); end
if ~isempty(exportPath), thermoweave.results.exportJSON(result,exportPath,5); end
if nargout==0, fprintf('ThermoWeave %s: peak %.3f K, cooling %.3f J, residual %.3g\n',result.schemaVersion,result.metrics.peakTemperature_K,result.metrics.coolingEnergy_J,result.energyResidualNormalized); clear result; end
end
