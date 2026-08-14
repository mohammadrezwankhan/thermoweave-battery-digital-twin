classdef Test3DStudy < matlab.unittest.TestCase
    % End-to-end contracts for the canonical synthetic 3-D study.

    methods (TestClassSetup)
        function installSource(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, 'src')));
        end
    end

    methods (Test)
        function canonicalResultHasThreeDimensionalState(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            scenario = fullfile(root, 'config', '3d-intercell-study.json');
            cfg = thermoweave.config.loadScenario(scenario);
            cfg.simulation.duration_s = 12;
            cfg.simulation.outputStep_s = 2;
            cfg.simulation.maxStep_s = 0.5;
            result = thermoweave.simulate(cfg);

            testCase.verifyEqual(result.schemaVersion, 'thermoweave.result/v1');
            testCase.verifySize(result.state.temperature_K, ...
                [numel(result.time_s) 36]);
            testCase.verifySize(result.state.soc, [numel(result.time_s) 36]);
            testCase.verifyEqual(result.topology.nodeCount, 36);
            testCase.verifyEqual(result.topology.gridSize, [3 4 3]);
            testCase.verifySize(result.signals.heatGeneration_W, ...
                [numel(result.time_s) 36]);
            testCase.verifyTrue(all(isfinite(result.state.temperature_K), 'all'));
            testCase.verifyGreaterThan(std(result.state.temperature_K(end, :)), 1e-6);
            testCase.verifyLessThanOrEqual(result.energyResidualNormalized, 1e-3);
        end

        function insulatedThreeDimensionalLatticeConservesUniformState(testCase)
            layout = struct('type', 'cuboid', 'rows', 2, 'columns', 2, ...
                'layers', 2, 'pitchX_m', 0.03, 'pitchY_m', 0.03, ...
                'pitchZ_m', 0.01, 'gx_W_per_K', 0.8, 'gy_W_per_K', 0.8, ...
                'gz_W_per_K', 0.3, 'zoneCount', 2);
            cfg = thermoweave.config.defaultConfig();
            cfg.layout = layout;
            cfg.cell.count = 8;
            cfg.simulation.duration_s = 8;
            cfg.simulation.outputStep_s = 2;
            cfg.cell.initialTemperature_K = 300;
            cfg.thermal.ambientConductance_W_per_K = 0;
            cfg.boundary.mode = 'scalar';
            cfg.boundary.temperature_K = 300;
            cfg.boundary.conductance_W_per_K = 0;
            cfg.electrical.current_A = 0;
            cfg.controller.mode = 'openloop';
            result = thermoweave.simulate(cfg);

            testCase.verifyEqual(result.state.temperature_K, ...
                repmat(300, numel(result.time_s), 8), 'AbsTol', 1e-10);
            testCase.verifyLessThanOrEqual(result.energyResidualNormalized, 1e-10);
        end

        function renderCreatesAccessibleDeterministicThreeDimensionalFigure(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            scenario = fullfile(root, 'config', '3d-intercell-study.json');
            cfg = thermoweave.config.loadScenario(scenario);
            cfg.simulation.duration_s = 2;
            cfg.simulation.outputStep_s = 1;
            result = thermoweave.simulate(cfg);
            figureHandle = thermoweave.visualization.render3DModule(result, ...
                'Visible', 'off');
            testCase.addTeardown(@() close(figureHandle));
            axesHandle = findobj(figureHandle, 'Type', 'axes');
            patches = findobj(axesHandle, 'Type', 'patch');
            labels = [string(axesHandle.XLabel.String), string(axesHandle.YLabel.String), ...
                string(axesHandle.ZLabel.String)];

            testCase.verifyEqual(numel(patches), 1);
            testCase.verifyEqual(size(patches.Vertices, 1), 8 * result.topology.nodeCount);
            testCase.verifyTrue(any(labels == "z (m)"));
            testCase.verifyNotEmpty(findobj(figureHandle, 'Type', 'colorbar'));
            testCase.verifyEqual(axesHandle.View, [35 24], 'AbsTol', 1e-12);
        end
    end
end
