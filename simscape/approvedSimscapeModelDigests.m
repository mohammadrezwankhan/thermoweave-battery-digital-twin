function digests = approvedSimscapeModelDigests()
%APPROVEDSIMSCAPEMODELDIGESTS SHA-256 pins for the owner-recorded E9 models.
%   The owner-recorded R2026a model and R2024a-compatible export are
%   documented in release-hold issue #25. These identities must be
%   independently reviewed before scientific release or pin rotation.
%   A pin is NOT itself a third-party licensing or scientific sign-off.
digests = [ ...
    "3921ed4f665b309fa8fd924b3899c087b843dfbef52a6888e09d9af3eec5bb9e"; ...
    "18ad387d658f52930209938881d50ad724a4e7038b8e756b094a82df1812adda"];
end
