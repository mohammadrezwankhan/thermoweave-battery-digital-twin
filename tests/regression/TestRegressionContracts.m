classdef TestRegressionContracts < matlab.unittest.TestCase
    % Reproducibility, canonical schema, fault metadata and optional adapter gates.

    properties (Access = private)
        ProjectRoot string
    end

    methods (TestClassSetup)
        function installSource(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, 'src')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, 'simscape')));
            testCase.ProjectRoot = string(root);
            originalRng = rng;
            testCase.addTeardown(@() rng(originalRng));
            rng(42, 'twister');
        end
    end

    methods (Test)
        function repeatedSeedReproducesConfigurationAndMetrics(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.variability.enabled = true;
            cfg.simulation.seed = 4401;
            cfg.simulation.duration_s = 8;
            cfg.simulation.outputStep_s = 2;
            first = thermoweave.simulate(cfg);
            second = thermoweave.simulate(cfg);
            testCase.verifyEqual(first.metadata.scenarioHash, second.metadata.scenarioHash);
            testCase.verifyEqual(first.metrics, second.metrics, 'AbsTol', 1e-12);
            testCase.verifyEqual(first.state.temperature_K, second.state.temperature_K, 'AbsTol', 1e-12);
            testCase.verifyEqual(jsonencode(first), jsonencode(second));
        end

        function canonicalSchemaAndExportManifestRemainTraceable(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 4;
            cfg.simulation.outputStep_s = 1;
            result = thermoweave.simulate(cfg);
            requiredTop = {'schemaVersion','time_s','state','boundary','control','signals', ...
                'metrics','topology','configuration','metadata','events'};
            testCase.verifyEqual(result.schemaVersion, 'thermoweave.result/v1');
            testCase.verifyTrue(all(isfield(result, requiredTop)));
            testCase.verifySize(result.state.temperature_K, [numel(result.time_s), cfg.cell.count]);
            testCase.verifySize(result.state.soc, [numel(result.time_s), cfg.cell.count]);
            testCase.verifySize(result.signals.current_A, [numel(result.time_s), 1]);
            exportPath = fullfile(testCase.ProjectRoot, 'tests', 'fixtures', 'result-regression.json');
            testCase.addTeardown(@() delete(exportPath));
            manifest = thermoweave.results.exportJSON(result, exportPath, 2);
            payload = fileread(exportPath);
            testCase.verifyEqual(manifest.sha256, thermoweave.util.hashText(payload));
            testCase.verifyEqual(manifest.bytes, numel(payload));
            testCase.verifyTrue(isfile(exportPath));
        end

        function declaredFaultsExposeMetadataAndPreserveDimensions(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 4;
            cfg.simulation.outputStep_s = 1;
            cfg.faults.events = struct('type', {'sensor_bias','coolant_blockage','heat_multiplier'}, ...
                'start_s', {0,0,0}, 'end_s', {4,4,4}, 'target', {1,'segment-2',3}, ...
                'magnitude', {5,0.1,2});
            result = thermoweave.simulate(cfg);
            testCase.verifySize(result.state.temperature_K, [numel(result.time_s), cfg.cell.count]);
            testCase.verifySize(result.state.soc, [numel(result.time_s), cfg.cell.count]);
            p = struct('ambientConductance_W_per_K', repmat(0.25, cfg.cell.count, 1), ...
                'coolantScale', 1, 'heatMultiplier', 1, 'currentScale', 1, ...
                'massFlow_kg_per_s', cfg.boundary.coolant.massFlow_kg_per_s);
            [~, active] = thermoweave.uncertainty.applyFaults(cfg, 1, p);
            testCase.verifyEqual(numel(active), 3);
            testCase.verifyEqual({active.type}, {'sensor_bias','coolant_blockage','heat_multiplier'});
            testCase.verifyEqual(active(2).magnitude, 0.1, 'AbsTol', 0);
            testCase.verifyEqual(active(3).magnitude, 2, 'AbsTol', 0);
        end

        function optionalSimscapeStatusIsExplicit(testCase)
            cfg = thermoweave.config.defaultConfig();
            report = runSimscapeScenario(cfg, ProjectRoot=testCase.ProjectRoot);
            allowedSkip = startsWith(string(report.status), 'SKIPPED_');
            testCase.verifyTrue(strcmp(string(report.status), 'PASS') || allowedSkip);
            isPass = strcmp(string(report.status), 'PASS');
            testCase.verifyTrue(~isPass || ~isempty(report.result));
            testCase.verifyTrue(~isPass || strcmp(report.result.schemaVersion, 'thermoweave.result/v1'));
        end

        function simscapeMapperCompletesCanonicalContract(testCase)
            cfg = thermoweave.config.defaultConfig();
            time = (0:2)';
            raw = struct('time_s', time, ...
                'temperature_K', repmat(298.15, 3, cfg.cell.count), ...
                'soc', repmat(0.8, 3, cfg.cell.count), ...
                'current_A', zeros(3, 1), ...
                'energyResidualNormalized', 0);
            result = mapSimscapeResults(raw, cfg);
            testCase.verifyEqual(result.schemaVersion, 'thermoweave.result/v1');
            testCase.verifyEqual(result.topology.nodeCount, cfg.cell.count);
            testCase.verifyTrue(isfield(result.metrics, 'peakTemperature_K'));
            testCase.verifySize(result.signals.current_A, [3 1]);
        end

        function simscapeMapperRejectsNoncanonicalCurrent(testCase)
            cfg = thermoweave.config.defaultConfig();
            raw = struct('time_s', (0:2)', ...
                'temperature_K', repmat(298.15, 3, cfg.cell.count), ...
                'soc', repmat(0.8, 3, cfg.cell.count), ...
                'current_A', zeros(3, cfg.cell.count));
            testCase.verifyError(@() mapSimscapeResults(raw, cfg), ...
                'thermoweave:simscape:SignalDimensions');
        end
    end
end
