function [modelPath, actualSha256] = verifyGeneratedModelManifest(projectRoot, manifest, trustedDigests)
%VERIFYGENERATEDMODELMANIFEST Bind an approved generated SLX to its exact bytes.
%   This offline validator requires a confined model path, a manifest digest,
%   and a separately source-pinned SHA-256 identity. It does not establish
%   licensed execution, independent approval, or real-cell validation.
arguments
    projectRoot (1,1) string
    manifest (1,1) struct
    trustedDigests string
end

if ~isfield(manifest, "modelFile")
    error("thermoweave:simscape:UnsafeModelPath", ...
        "The model manifest must identify a confined SLX file.");
end
rel = string(manifest.modelFile);
if ~isscalar(rel) || ismissing(rel) || isempty(regexp(char(rel), ...
        "^(simscape/models/)?[A-Za-z0-9_][A-Za-z0-9_-]*[.]slx$", "once"))
    error("thermoweave:simscape:UnsafeModelPath", ...
        "modelFile must be a simple SLX filename under simscape/models.");
end
[~, stem, ext] = fileparts(char(rel));
folder = string(char(java.io.File(char(fullfile(projectRoot, ...
    "simscape", "models"))).getCanonicalPath()));
modelPath = string(char(java.io.File(char(fullfile(folder, ...
    string(stem) + string(ext)))).getCanonicalPath()));
if ~startsWith(modelPath, folder + string(filesep))
    error("thermoweave:simscape:UnsafeModelPath", ...
        "The resolved model must stay within simscape/models.");
end

if ~isfield(manifest, "modelSha256")
    error("thermoweave:simscape:MissingModelDigest", ...
        "The manifest must declare the exact executing model SHA-256.");
end
declared = lower(string(manifest.modelSha256));
if ~isscalar(declared) || ismissing(declared) || ...
        isempty(regexp(char(declared), "^[0-9a-f]{64}$", "once"))
    error("thermoweave:simscape:MissingModelDigest", ...
        "modelSha256 must be a complete 64-character SHA-256 digest.");
end
if ~isfile(modelPath)
    error("thermoweave:simscape:ModelFileMissing", ...
        "The declared generated model file is missing.");
end
fid = fopen(char(modelPath), "rb");
if fid < 0
    error("thermoweave:simscape:ModelFileMissing", ...
        "The declared generated model file cannot be opened.");
end
cleaner = onCleanup(@() fclose(fid));
md = java.security.MessageDigest.getInstance("SHA-256");
while true
    bytes = fread(fid, 1048576, "*uint8");
    if isempty(bytes)
        break
    end
    md.update(bytes);
end
digestBytes = typecast(md.digest(), "uint8");
actualSha256 = lower(string(reshape(dec2hex(digestBytes, 2).', 1, [])));
if actualSha256 ~= declared
    error("thermoweave:simscape:ModelDigestMismatch", ...
        "The executing SLX bytes do not match the model manifest.");
end
trusted = lower(string(trustedDigests(:)));
if isempty(trusted) || any(strlength(trusted) ~= 64) || ...
        ~any(actualSha256 == trusted)
    error("thermoweave:simscape:UnapprovedModel", ...
        "The executing SLX is not among the source-pinned model digests.");
end
end
