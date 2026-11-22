classdef TestSimscapeModelProvenance < matlab.unittest.TestCase
    % Offline model-byte identity tests; do not require Simulink or a licensed SLX.

    methods (TestClassSetup)
        function installSource(testCase)
            root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, "src")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, "simscape")));
        end
    end

    methods (Test)
        function exactPinnedFixtureIsAccepted(testCase)
            [root, manifest, digest] = fixture(testCase);
            [modelPath, actual] = verifyGeneratedModelManifest(root, manifest, digest);
            testCase.verifyEqual(actual, digest);
            testCase.verifyEqual(modelPath, fullfile(root, "simscape", "models", "native_e9.slx"));
        end

        function missingDeclaredDigestFailsClosed(testCase)
            [root, manifest, digest] = fixture(testCase);
            manifest = rmfield(manifest, "modelSha256");
            testCase.verifyError(@() verifyGeneratedModelManifest(root, manifest, digest), ...
                "thermoweave:simscape:MissingModelDigest");
        end

        function modifiedModelBytesFailClosed(testCase)
            [root, manifest, digest] = fixture(testCase);
            path = fullfile(root, "simscape", "models", "native_e9.slx");
            fid = fopen(path, "ab");
            fwrite(fid, uint8("tampered"), "uint8");
            fclose(fid);
            testCase.verifyError(@() verifyGeneratedModelManifest(root, manifest, digest), ...
                "thermoweave:simscape:ModelDigestMismatch");
        end

        function traversalAndAbsolutePathsAreRejected(testCase)
            [root, manifest, digest] = fixture(testCase);
            paths = ["../native_e9.slx", "simscape/models/../native_e9.slx", ...
                "/tmp/native_e9.slx", "C:\\temp\\native_e9.slx"];
            for path = paths
                manifest.modelFile = path;
                testCase.verifyError(@() verifyGeneratedModelManifest(root, manifest, digest), ...
                    "thermoweave:simscape:UnsafeModelPath");
            end
        end

        function unapprovedModelDigestFailsClosed(testCase)
            [root, manifest, ~] = fixture(testCase);
            testCase.verifyError(@() verifyGeneratedModelManifest(root, manifest, ...
                repmat("0", 1, 64)), "thermoweave:simscape:UnapprovedModel");
        end
    end
end

function [root, manifest, digest] = fixture(testCase)
root = string(tempname);
modelDir = fullfile(root, "simscape", "models");
mkdir(modelDir);
testCase.addTeardown(@() rmdir(root, "s"));
bytes = uint8("synthetic provenance fixture - not an approved Simscape model");
fid = fopen(fullfile(modelDir, "native_e9.slx"), "wb");
assert(fid > 0);
fwrite(fid, bytes, "uint8");
fclose(fid);
digest = string(thermoweave.util.hashText(char(bytes)));
manifest = struct("modelFile", "simscape/models/native_e9.slx", ...
    "modelSha256", digest, "outputContract", "thermoweave.native-e9/v1");
end
