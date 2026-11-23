classdef TestReleaseArchive < matlab.unittest.TestCase
    methods (Test)
        function archivesReviewedPathsAndFreshGeneratedEvidence(testCase)
            project = fileparts(fileparts(fileparts(mfilename("fullpath"))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(project, "src")));
            workspace = testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
            root = string(workspace.Folder);
            mkdir(fullfile(root, "tools"));
            mkdir(fullfile(root, "simscape", "models"));
            mkdir(fullfile(root, "artifacts", "reports"));
            tools = fullfile(root, "tools");
            copyfile(fullfile(project, "tools", "packageRelease.m"), tools);
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(tools));

            testCase.assertEqual(system("git init --quiet"), 0);
            writelines("Public source", fullfile(root, "simscape", "README.md"));
            receipt = fullfile(root, "artifacts", "reports", "verification.json");
            writelines("checked-in evidence", receipt);
            testCase.assertEqual(system("git add -- tools simscape artifacts"), 0);
            testCase.assertEqual(system( ...
                "git -c user.name=ThermoWeave -c user.email=fixture@example.invalid " + ...
                "-c commit.gpgsign=false commit --quiet -m fixture"), 0);

            writelines("fresh evidence", receipt);
            localModel = fullfile(root, "simscape", "models", "local.slx");
            writelines("placeholder model", localModel);
            testCase.assertEqual(system("git add -- simscape/models/local.slx"), 0);
            writelines("private model metadata", ...
                fullfile(root, "simscape", "models", "thermoweave-model-manifest.json"));
            writelines("raw local output", fullfile(root, "artifacts", "local-note.txt"));

            mkdir(fullfile(root, "release"));
            zip(fullfile(root, "release", "thermoweave-source.zip"), ...
                "artifacts/local-note.txt", root);

            manifest = packageRelease();
            destination = fullfile(root, "unpacked");
            unzip(manifest.archive, destination);

            testCase.verifyTrue(isfile(fullfile(destination, "simscape", "README.md")));
            testCase.verifyEqual(strtrim(string(fileread( ...
                fullfile(destination, "artifacts", "reports", "verification.json")))), ...
                "fresh evidence");
            testCase.verifyFalse(isfile(fullfile(destination, "simscape", "models", "local.slx")));
            testCase.verifyFalse(isfile(fullfile(destination, "simscape", "models", ...
                "thermoweave-model-manifest.json")));
            testCase.verifyFalse(isfile(fullfile(destination, "artifacts", "local-note.txt")));
        end
    end
end
