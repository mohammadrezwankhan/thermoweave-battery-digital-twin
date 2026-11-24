function validateSeed(seed, name)
%VALIDATESEED Validate a deterministic MATLAB random stream seed.
if ~isnumeric(seed) || ~isscalar(seed) || ~isreal(seed)
    error('thermoweave:config:Range', ...
        '%s must be an integer from 0 to 4294967295.', name);
end
value = double(seed);
if ~isfinite(value) || value < 0 || value >= 2^32 || value ~= fix(value)
    error('thermoweave:config:Range', ...
        '%s must be an integer from 0 to 4294967295.', name);
end
end
