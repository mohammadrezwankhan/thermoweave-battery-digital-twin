function cfg = loadScenario(source)
%LOADSCENARIO Load JSON or merge a scenario struct with defaults.
if nargin == 0 || isempty(source)
    source = thermoweave.config.defaultConfig();
elseif ischar(source) || (isstring(source) && isscalar(source))
    path = char(source);
    if ~isfile(path), error('thermoweave:config:FileNotFound','Scenario file not found: %s',path); end
    try
        source = jsondecode(fileread(path));
    catch ME
        error('thermoweave:config:InvalidJSON','Unable to decode scenario JSON: %s',ME.message);
    end
elseif ~isstruct(source)
    error('thermoweave:config:Type','Scenario must be a struct or JSON path.');
end
cfg = merge(thermoweave.config.defaultConfig(),source);
cfg = thermoweave.config.validateConfig(cfg);
end

function out = merge(base, override)
out = base;
names = fieldnames(override);
for k=1:numel(names)
    n = names{k}; v = override.(n);
    if isfield(out,n) && isstruct(out.(n)) && isstruct(v)
        out.(n) = merge(out.(n),v);
    else
        out.(n) = v;
    end
end
end
