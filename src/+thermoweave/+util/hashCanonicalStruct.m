function digest = hashCanonicalStruct(value)
%HASHCANONICALSTRUCT Versioned recursive canonical JSON SHA-256.
% Unlike legacy hashStruct, this v1 digest sorts every object key,
% rejects non-finite/complex data and normalizes negative numeric zero.
% Existing result/v1 scenarioHash remains the original legacy digest.
canonical = normalize(value);
payload = ['thermoweave.canonical-json/v1' newline jsonencode(canonical)];
digest = thermoweave.util.hashText(payload);
end

function out = normalize(value)
if isstruct(value)
    out = orderfields(value);
    names = fieldnames(out);
    for k = 1:numel(out)
        for j = 1:numel(names)
            name = names{j};
            out(k).(name) = normalize(out(k).(name));
        end
    end
elseif isnumeric(value)
    if ~isreal(value) || any(~isfinite(value(:)))
        error('thermoweave:hash:Nonfinite', ...
            'Canonical JSON accepts only finite real numeric values.');
    end
    out = value;
    out(out == 0) = 0; % Canonicalize IEEE-754 negative zero.
elseif islogical(value) || ischar(value) || isstring(value)
    out = value;
elseif iscell(value)
    out = cell(size(value));
    for k = 1:numel(value)
        out{k} = normalize(value{k});
    end
else
    error('thermoweave:hash:Unsupported', ...
        'Unsupported canonical JSON value type: %s.', class(value));
end
end
