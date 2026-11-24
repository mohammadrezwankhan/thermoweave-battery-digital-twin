classdef TestSimulationIntegration < matlab.unittest.TestCase
    % Integration tests for the public simulation, controller and result APIs.

    methods (TestClassSetup)
        function installSource(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, 'src')));
            originalRng = rng;
            testCase.addTeardown(@() rng(originalRng));
            rng(42, 'twister');
        end
    end

    methods (Test)
        function isothermalE0RemainsExactlyAtEquilibrium(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 10;
            cfg.simulation.outputStep_s = 1;
            cfg.cell.initialTemperature_K = 300;
            cfg.thermal.ambientTemperature_K = 300;
            cfg.boundary.temperature_K = 300;
            cfg.electrical.current_A = 0;
            cfg.electrical.entropicHeat = false;
            cfg.controller.mode = 'openloop';
            cfg.simulation.relativeTolerance = 1e-10;
            cfg.simulation.absoluteTolerance = 1e-12;
            result = thermoweave.simulate(cfg);
            spread = max(result.state.temperature_K, [], 2) - min(result.state.temperature_K, [], 2);
            drift = max(abs(result.state.temperature_K(:) - 300));
            testCase.verifyLessThanOrEqual(max(spread), 1e-10);
            testCase.verifyLessThanOrEqual(drift, 1e-10);
            testCase.verifyLessThanOrEqual(result.metrics.energyResidualNormalized, 1e-10);
            testCase.verifyEmpty(result.events);
        end

        function thermalRelaxationMovesTowardAmbient(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 30;
            cfg.simulation.outputStep_s = 2;
            cfg.cell.initialTemperature_K = 310;
            cfg.thermal.ambientTemperature_K = 298.15;
            cfg.boundary.temperature_K = 298.15;
            cfg.electrical.current_A = 0;
            result = thermoweave.simulate(cfg);
            initialMean = mean(result.state.temperature_K(1, :));
            finalMean = mean(result.state.temperature_K(end, :));
            testCase.verifyLessThan(finalMean, initialMean);
            testCase.verifyGreaterThan(finalMean, cfg.thermal.ambientTemperature_K);
        end

        function energyAccountingAndSolverConvergenceAgree(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 20;
            cfg.simulation.outputStep_s = 2;
            cfg.electrical.current_A = 5;
            cfg.simulation.solver = 'ode15s';
            stiffResult = thermoweave.simulate(cfg);
            cfg.simulation.solver = 'ode45';
            explicitResult = thermoweave.simulate(cfg);
            finalDifference = max(abs(stiffResult.state.temperature_K(end, :) - ...
                explicitResult.state.temperature_K(end, :)));
            testCase.verifyLessThanOrEqual(stiffResult.metrics.energyResidualNormalized, 1e-4);
            testCase.verifyLessThanOrEqual(explicitResult.metrics.energyResidualNormalized, 1e-4);
            testCase.verifyLessThanOrEqual(finalDifference, 1e-4);
        end

        function signalHistoriesUseTheirDeclaredSampleTimes(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 2;
            cfg.simulation.outputStep_s = 1;
            cfg.controller.mode = 'openloop';
            cfg.electrical.currentProfile = struct('time_s', [0; 1; 2], ...
                'current_A', [1; 2; 3]);
            result = thermoweave.simulate(cfg);
            testCase.verifyEqual(result.time_s, [0; 1; 2]);
            testCase.verifyEqual(result.signals.current_A, [1; 2; 3]);
            initialHeat = thermoweave.electrical.heatGeneration( ...
                result.state.temperature_K(1, :)', ...
                result.state.soc(1, :)', 1, cfg);
            testCase.verifyEqual(result.signals.heatGeneration_W(1, :)', ...
                initialHeat, 'AbsTol', 1e-12);
        end

        function durationShorterThanOutputStepReturnsTwoRows(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 0.1;
            cfg.simulation.outputStep_s = 1;
            for solver = ["ode45", "ode15s"]
                cfg.simulation.solver = char(solver);
                result = thermoweave.simulate(cfg);
                testCase.verifyEqual(result.time_s, [0; 0.1]);
                testCase.verifyEqual(result.metadata.timeBase_s, result.time_s);
                testCase.verifySize(result.state.temperature_K, [2 cfg.cell.count]);
                testCase.verifySize(result.control.zoneCommand, [2 cfg.layout.zoneCount]);
                testCase.verifyEqual(result.signals.current_A, [5; 5]);
            end
        end

        function decimalOutputGridDoesNotRepeatControllerTicks(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 1.1;
            cfg.simulation.outputStep_s = 0.1;
            cfg.controller.samplePeriod_s = 0.3;
            cfg.controller.referenceTemperature_K = 250;
            cfg.controller.rateLimit_per_s = 0.2;

            tickTimes = (0:3)' * cfg.controller.samplePeriod_s;
            step = cfg.controller.rateLimit_per_s * cfg.controller.samplePeriod_s;
            sampleTimes = (0:cfg.simulation.outputStep_s:cfg.simulation.duration_s)';
            expected = repmat(sum(sampleTimes >= tickTimes', 2) * step, ...
                1, cfg.layout.zoneCount);
            for solver = ["ode45", "ode15s"]
                cfg.simulation.solver = char(solver);
                result = thermoweave.simulate(cfg);
                testCase.verifyEqual(result.time_s, sampleTimes);
                testCase.verifyEqual(result.control.zoneCommand, expected, ...
                    'AbsTol', 1e-12, sprintf('%s controller command', solver));
            end
        end

        function nearbyCurrentTransitionDoesNotOverwriteEarlierOutput(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 2;
            cfg.simulation.outputStep_s = 1;
            cfg.controller.mode = 'openloop';
            cfg.electrical.currentProfile = struct( ...
                'time_s', [0; 1 + 8*eps(1); 2], 'current_A', [1; 2; 3]);

            for solver = ["ode45", "ode15s"]
                cfg.simulation.solver = char(solver);
                result = thermoweave.simulate(cfg);
                testCase.verifyEqual(result.time_s, [0; 1; 2]);
                testCase.verifyEqual(result.signals.current_A, [1; 1; 3], ...
                    sprintf('%s sampled current', solver));
            end
        end

        function externalHeatPreservesEnergyAccounting(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 4;
            cfg.simulation.outputStep_s = 1;
            cfg.controller.mode = 'openloop';
            cfg.thermal.externalHeat_W = 2;
            result = thermoweave.simulate(cfg);
            testCase.verifyLessThanOrEqual( ...
                result.metrics.energyResidualNormalized, 1e-4);
        end

        function storagePermutationPreservesSymmetricChainBehavior(testCase)
            cfgA = thermoweave.config.defaultConfig();
            cfgA.layout.rows = 1;
            cfgA.layout.columns = 4;
            cfgA.layout.zoneCount = 2;
            cfgA.cell.count = 4;
            cfgA.simulation.duration_s = 10;
            cfgA.simulation.outputStep_s = 1;
            cfgA.controller.mode = 'openloop';
            cfgA.electrical.current_A = 0;
            cfgA.boundary.mode = 'vector';
            cfgA.boundary.temperature_K = [298.15; 299.15; 300.15; 301.15];
            cfgA.boundary.conductance_W_per_K = repmat(0.5, 4, 1);
            cfgB = cfgA;
            cfgB.boundary.temperature_K = flipud(cfgA.boundary.temperature_K);
            resultA = thermoweave.simulate(cfgA);
            resultB = thermoweave.simulate(cfgB);
            testCase.verifyEqual(resultA.state.temperature_K, ...
                resultB.state.temperature_K(:, end:-1:1), 'AbsTol', 1e-9);
        end

        function prescribedGradientPreservesNodeSpecificOrdering(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            cfg = thermoweave.config.loadScenario(fullfile(root, 'config', ...
                'vectorized-gradient.json'));
            cfg.simulation.duration_s = 30;
            result = thermoweave.simulate(cfg);
            testCase.verifyEqual(result.boundary.temperature_K, ...
                repmat(cfg.boundary.temperature_K(:)', numel(result.time_s), 1), ...
                'AbsTol', 1e-12);
            testCase.verifyGreaterThan(numel(unique(cfg.boundary.temperature_K)), 4);
            testCase.verifyGreaterThan(std(result.state.temperature_K(end, :)), 0);
            testCase.verifyLessThanOrEqual(result.energyResidualNormalized, 1e-4);
        end

        function reversingCoolantSegmentsChangesSpatialPattern(testCase)
            cfgForward = thermoweave.config.defaultConfig();
            cfgForward.boundary.mode = 'coolant';
            cfgForward.controller.mode = 'openloop';
            cfgForward.electrical.current_A = 0;
            cfgForward.cell.initialTemperature_K = linspace(299, 304, cfgForward.cell.count)';
            cfgForward.simulation.duration_s = 20;
            cfgForward.simulation.outputStep_s = 2;
            topology = thermoweave.thermal.buildTopology(cfgForward.layout);
            cfgForward.boundary.coolant.segmentNodes = topology.zoneId;
            cfgReverse = cfgForward;
            cfgReverse.boundary.coolant.segmentNodes = 1 + max(topology.zoneId) - topology.zoneId;
            forward = thermoweave.simulate(cfgForward);
            reverse = thermoweave.simulate(cfgReverse);
            difference = max(abs(forward.state.temperature_K(end, :) - ...
                reverse.state.temperature_K(end, :)));
            testCase.verifyGreaterThan(difference, 1e-6);
            testCase.verifyLessThanOrEqual(forward.energyResidualNormalized, 1e-4);
            testCase.verifyLessThanOrEqual(reverse.energyResidualNormalized, 1e-4);
        end

        function baselineControllerRespectsBoundsAndRateLimit(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.controller.rateLimit_per_s = 0.1;
            input = struct('temperature_K', repmat(310, cfg.cell.count, 1), ...
                'zoneId', thermoweave.thermal.buildTopology(cfg.layout).zoneId, ...
                'zoneWeights', ones(cfg.cell.count, 1), ...
                'referenceTemperature_K', 298.15, 'elapsedStep_s', 1);
            [first, state] = thermoweave.control.baselineController(input, cfg);
            input.temperature_K = repmat(290, cfg.cell.count, 1);
            [second, ~] = thermoweave.control.baselineController(input, cfg, state);
            testCase.verifyGreaterThanOrEqual(first, 0);
            testCase.verifyLessThanOrEqual(first, 1);
            testCase.verifyLessThanOrEqual(first, 0.1 + 1e-12);
            testCase.verifyGreaterThanOrEqual(second, first - 0.1 - 1e-12);
            testCase.verifyLessThanOrEqual(second, first + 0.1 + 1e-12);
        end

        function advancedControllerCoolsHotZonesAndHonorsRate(testCase)
            testCase.assumeTrue(exist('quadprog','file') == 2 && ...
                license('test','Optimization_Toolbox'), 'Optimization Toolbox unavailable.');
            cfg = thermoweave.config.defaultConfig();
            cfg.controller.rateLimit_per_s = 0.1;
            topology = thermoweave.thermal.buildTopology(cfg.layout);
            input = struct('temperature_K', repmat(350, cfg.cell.count, 1), ...
                'zoneId', topology.zoneId, 'zoneWeights', ones(cfg.cell.count, 1), ...
                'referenceTemperature_K', 298.15, 'elapsedStep_s', 1);
            [command, info] = thermoweave.control.advancedController(input, cfg);
            testCase.verifyEqual(info.status, 'OPTIMAL', info.message);
            testCase.verifyFalse(info.usedFallback);
            testCase.verifyEqual(command, 0.1 * ones(cfg.controller.zoneCount,1), 'AbsTol', 1e-8);
            testCase.verifyGreaterThan(command, 0);
            testCase.verifyLessThanOrEqual(command, 0.1 + 1e-10);
        end

        function e3PulseBaselineMeetsPredeclaredBenefit(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 300;
            cfg.simulation.outputStep_s = 2;
            cfg.cell.initialTemperature_K = 298.15;
            cfg.boundary.temperature_K = 298.15;
            cfg.thermal.ambientTemperature_K = 298.15;
            cfg.electrical.currentProfile = struct('time_s', [0; 60; 240; 241; 300], ...
                'current_A', [0; 10; 10; 0; 0]);
            cfg.electrical.current_A = 0;
            cfgOpen = cfg;
            cfgOpen.controller.mode = 'openloop';
            cfgBase = cfg;
            cfgBase.controller.mode = 'baseline';
            openResult = thermoweave.simulate(cfgOpen);
            baseResult = thermoweave.simulate(cfgBase);
            peakRiseOpen = openResult.metrics.peakTemperature_K - cfg.cell.initialTemperature_K;
            peakRiseBase = baseResult.metrics.peakTemperature_K - cfg.cell.initialTemperature_K;
            reduction = (peakRiseOpen - peakRiseBase) / max(peakRiseOpen, eps);
            testCase.verifyGreaterThanOrEqual(reduction, 0.15);
            testCase.verifyLessThanOrEqual(baseResult.metrics.peakTemperature_K, 318.15);
            testCase.verifyLessThanOrEqual(baseResult.metrics.energyResidualNormalized, 1e-4);
        end
    end
end
