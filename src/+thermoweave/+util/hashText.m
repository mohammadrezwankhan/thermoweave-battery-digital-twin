function h=hashText(txt)
%HASHTEXT Return a SHA-256 hash for a character payload.
md=java.security.MessageDigest.getInstance('SHA-256'); bytes=uint8(unicode2native(char(txt),'UTF-8')); md.update(bytes); d=typecast(md.digest(),'uint8'); h=lower(reshape(dec2hex(d,2).',1,[]));
end
