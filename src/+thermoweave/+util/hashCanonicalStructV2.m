function [digest, algorithm] = hashCanonicalStructV2(value)
%HASHCANONICALSTRUCTV2 Hash typed MATLAB configuration values as canonical JSON.
% Each node records its class, shape, and column-major contents. Numeric
% elements use hexadecimal encodings and text uses UTF-16 code units.
algorithm = 'thermoweave.canonical-json/v2';
payload = [algorithm newline jsonencode(typedNode(value))];
digest = thermoweave.util.hashText(payload);
end

function node = typedNode(value)
if isstruct(value)
    names = sort(fieldnames(value));
    fields = cell(numel(names), numel(value));
    for k = 1:numel(value)
        for j = 1:numel(names)
            fields{j,k} = typedNode(value(k).(names{j}));
        end
    end
    data = {cellfun(@textUnits, names.', 'UniformOutput', false), fields(:).'};
elseif iscell(value)
    data = cellfun(@typedNode, value(:).', 'UniformOutput', false);
elseif isnumeric(value)
    data = numericElements(value);
elseif islogical(value)
    data = num2cell(full(value(:).'));
elseif ischar(value)
    data = textUnits(value);
elseif isstring(value)
    data = cell(1, numel(value));
    for k = 1:numel(value)
        if ismissing(value(k))
            data{k} = false;
        else
            data{k} = textUnits(char(value(k)));
        end
    end
else
    error('thermoweave:hash:Unsupported', ...
        'Unsupported canonical JSON value type: %s.', class(value));
end
node = {class(value), size(value), data};
end

function data = numericElements(value)
if ~isreal(value) || any(isnan(value(:)))
    error('thermoweave:hash:Nonfinite', ...
        'Canonical JSON rejects complex and NaN numeric values.');
end
if isempty(value)
    data = {};
    return
end
elements = full(value(:));
if isfloat(elements)
    elements(elements == 0) = 0;
    digits = num2hex(elements);
else
    digits = dec2hex(elements, 16);
end
data = cellstr(lower(digits)).';
end

function units = textUnits(value)
units = num2cell(double(value(:).'));
end
