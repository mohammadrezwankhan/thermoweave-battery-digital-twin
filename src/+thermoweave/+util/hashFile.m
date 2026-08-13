function digest = hashFile(path)
%HASHFILE Return a lowercase SHA-256 digest for a file.

file = fopen(path, "r");
if file < 0
    error("thermoweave:hash:IO", "Unable to open file '%s'.", path);
end
cleanup = onCleanup(@() fclose(file));
bytes = fread(file, Inf, "*uint8");
engine = java.security.MessageDigest.getInstance("SHA-256");
engine.update(bytes);
digest = lower(reshape(dec2hex(typecast(engine.digest(), "uint8"))', 1, []));
end
