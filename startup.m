function root = startup()
%STARTUP Add ThermoWeave source folders to the MATLAB path.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'src'));
addpath(fullfile(root,'simscape'));
addpath(fullfile(root,'tools'));
if nargout == 0
    clear root
end
end
