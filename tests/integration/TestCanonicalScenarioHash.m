classdef TestCanonicalScenarioHash < matlab.unittest.TestCase
    % Compare the v1 hashes for the checked-in scenarios across MATLAB releases.
    properties (Access = private)
        repoRoot
    end

    properties (TestParameter)
        % Known digests from the signed source in MATLAB R2026a (d8466ee).
        scenario = struct( ...
            'intercell3d', struct('file', '3d-intercell-study.json', ...
                'digest', 'b1cf5b3d9973ae6417f5a0e60e5a45e6ea9cb0ad90e6658cf2c2319e75ba1a02', ...
                'digestV2', '03a15968c03e924bcddc9861dfc0f20c089fef602f1cda9b0e8e01925863817b'), ...
            'baseline', struct('file', 'baseline.json', ...
                'digest', '602ebcdcfaedd4e544fb0d67081f2343606f6b3940d195e9d23676428e44fb33', ...
                'digestV2', 'cf6c839d410b3f57d5d9141aa283cfd5ab2aca481249983860d9e7360c3d6d7a'), ...
            'channelRestriction', struct('file', 'channel-restriction.json', ...
                'digest', 'e1ea70da84c82d9e1149cf42cb9e0c834e7b958aeb692a911322f32dd56da655', ...
                'digestV2', '117fc5609a0501a5e081b6e6082af2ca79642666d05b73e6af9bd8c018d32b7e'), ...
            'nonuniformCooling', struct('file', 'nonuniform-cooling.json', ...
                'digest', '077623fd567a85e28232f292332347f97df8dc71b6b6822940abd0d279b07187', ...
                'digestV2', '8be5eb560740ef30f6960faa3f6bbff22bf9aca97e42de35b52101ded3341c93'), ...
            'sensorFault', struct('file', 'sensor-fault.json', ...
                'digest', 'fdce1f0a90482c3052cc16d35679fe90a39f2f952fe231e1e9694862e4c70144', ...
                'digestV2', '5fae229feaf9481b5019eb45e0e66c6eb5a32d5d5ccaae4bddbc9acdf3db91ff'), ...
            'vectorizedGradient', struct('file', 'vectorized-gradient.json', ...
                'digest', 'ed2b773d1fbe953d7892c3217577f3006a8bf706ad84fb923fff1ee886b8541d', ...
                'digestV2', 'f92172b5744f74bda8fa7b252fe58a7385177f376ae18d9931dca89755024a5a'));
    end

    methods (TestClassSetup)
        function sourceOnPath(testCase)
            testCase.repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.repoRoot, 'src')));
        end
    end

    methods (Test)
        function checkedInScenarioMatchesR2026aDigest(testCase, scenario)
            cfg = thermoweave.config.loadScenario( ...
                fullfile(testCase.repoRoot, 'config', scenario.file));
            digest = thermoweave.util.hashCanonicalStruct(cfg);
            testCase.verifyEqual(digest, scenario.digest);
            testCase.verifyEqual(thermoweave.util.hashCanonicalStructV2(cfg), ...
                scenario.digestV2);
        end

        function independentPortableFixtureMatchesDigest(testCase)
            % SHA-256 of the version line and the independently encoded JSON:
            % {"bias":0,"nested":{"list":[1.25,{"thermoweaveNumberType":"PositiveInfinity"},{"thermoweaveNumberType":"NegativeInfinity"}],"ok":true}}
            value = struct('nested', struct('ok', true, 'list', [1.25, Inf, -Inf]), ...
                'bias', -0.0);
            digest = thermoweave.util.hashCanonicalStruct(value);
            testCase.verifyEqual(digest, ...
                '117385144712b7002d0b28b9669bebf049b22d85c2569845cabf1cecfb7384d7');
        end

        function v2DistinguishesInfinityFromUserAnnotations(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 2;
            cfg.auditAnnotation.value = Inf;
            tagged = cfg;
            tagged.auditAnnotation.value = struct( ...
                'thermoweaveNumberType', 'PositiveInfinity');

            numericResult = thermoweave.simulate(cfg);
            objectResult = thermoweave.simulate(tagged);

            testCase.verifyEqual(numericResult.metadata.scenarioCanonicalHash, ...
                objectResult.metadata.scenarioCanonicalHash);
            testCase.verifyEqual(numericResult.metadata.scenarioCanonicalHashAlgorithm, ...
                'thermoweave.canonical-json/v1');
            testCase.verifyEqual(numericResult.metadata.scenarioCanonicalHashV2Algorithm, ...
                'thermoweave.canonical-json/v2');
            testCase.verifyNotEqual(numericResult.metadata.scenarioCanonicalHashV2, ...
                objectResult.metadata.scenarioCanonicalHashV2);
        end

        function v2MatchesIndependentTypedFixture(testCase)
            value = struct('nested', struct('ok', true, 'list', [1.25, Inf, -Inf]), ...
                'bias', -0.0);
            reordered = struct('bias', 0, ...
                'nested', struct('list', [1.25, Inf, -Inf], 'ok', true));
            expected = '7dd407748eea940c6229229e10cdcb9691c0a962b515477692e23f9e6f769d73';
            testCase.verifyEqual(thermoweave.util.hashCanonicalStructV2(value), expected);
            testCase.verifyEqual(thermoweave.util.hashCanonicalStructV2(reordered), expected);
        end

        function v2PreservesKindsShapesAndLargeIntegers(testCase)
            hash = @thermoweave.util.hashCanonicalStructV2;
            large = bitshift(uint64(1), 53);
            testCase.verifyNotEqual(hash([1 2]), hash([1; 2]));
            testCase.verifyNotEqual(hash([1 2]), hash({1, 2}));
            testCase.verifyNotEqual(hash(single(1)), hash(1));
            testCase.verifyNotEqual(hash(large), hash(large + uint64(1)));
            testCase.verifyNotEqual(hash(string(missing)), hash(""));
            testCase.verifyNotEqual(hash(char(955)), hash(string(char(955))));
        end

        function v2RejectsNaNAndComplexValues(testCase)
            hash = @thermoweave.util.hashCanonicalStructV2;
            testCase.verifyError(@() hash(NaN), 'thermoweave:hash:Nonfinite');
            testCase.verifyError(@() hash(1 + 2i), 'thermoweave:hash:Nonfinite');
        end
    end
end
