classdef TestAuditRegressions < matlab.unittest.TestCase
    % Independent regression oracles for focused engineering-audit fixes.

    methods (TestClassSetup)
        function installSource(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, 'src')));
        end
    end

    methods (Test)
        function deadbandUsesKelvinBeforeProportionalGain(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.controller.Kp_per_K = 0.2;
            cfg.controller.deadband_K = 1;
            cfg.controller.rateLimit_per_s = Inf;
            topo = thermoweave.thermal.buildTopology(cfg.layout);
            input = struct('temperature_K', repmat(300.15, cfg.cell.count, 1), ...
                'zoneId', topo.zoneId, 'zoneWeights', ones(cfg.cell.count, 1), ...
                'referenceTemperature_K', 298.15, 'elapsedStep_s', 1);
            [command, ~] = thermoweave.control.baselineController(input, cfg);
            % Two kelvin of excess temperature, minus a one-kelvin
            % deadband, times the 0.2 K^-1 gain is a command of 0.2.
            testCase.verifyEqual(command, 0.2 * ones(cfg.layout.zoneCount, 1), ...
                'AbsTol', 1e-12);
        end

        function stuckActuatorHoldsAppliedCommandWithoutSlewJump(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 6;
            cfg.simulation.outputStep_s = 1;
            cfg.controller.samplePeriod_s = 1; % Exercise one clock update per output sample.
            cfg.cell.initialTemperature_K = 350;
            cfg.boundary.temperature_K = 350;
            cfg.thermal.ambientTemperature_K = 350;
            cfg.electrical.current_A = 0;
            cfg.controller.rateLimit_per_s = 0.1;
            cfg.faults.events = struct('type', 'stuck_actuator', ...
                'start_s', 2, 'end_s', 4, 'target', 2, 'magnitude', 1);
            result = thermoweave.simulate(cfg);
            command = result.control.zoneCommand(:, 2);
            testCase.verifyGreaterThan(command(2), 0);
            testCase.verifyLessThan(command(2), 1);
            testCase.verifyEqual(command(3:5), repmat(command(2), 3, 1), ...
                'AbsTol', 1e-12);
            testCase.verifyGreaterThan(command(6), command(5));
            testCase.verifyLessThanOrEqual(max(abs(diff(command))), 0.1 + 1e-12);
        end

        function inactiveCoolantSegmentsKeepLastDefinedTemperature(testCase)
            cellT = [300; 310];
            inlet = 299.15;
            [segmentT, heat] = thermoweave.coolant.march( ...
                cellT, zeros(2, 3), inlet, 0, 3800);
            testCase.verifyEqual(segmentT, repmat(inlet, 3, 1), ...
                'AbsTol', 0);
            testCase.verifyEqual(heat, zeros(3, 1), 'AbsTol', 0);

            cfg = thermoweave.config.defaultConfig();
            cfg.boundary.mode = 'coolant';
            cfg.boundary.coolant.massFlow_kg_per_s = 0; % A complete pump-loss state.
            cfg.boundary.coolant.segmentConductance_W_per_K = 0;
            topo = thermoweave.thermal.buildTopology(cfg.layout);
            boundary = thermoweave.coolant.evaluate( ...
                repmat(300, cfg.cell.count, 1), cfg, topo, [], 0);
            testCase.verifyEqual(boundary.coolantTemperature_K, ...
                repmat(cfg.boundary.coolant.inletTemperature_K, ...
                cfg.boundary.coolant.segments, 1), 'AbsTol', 0);
            testCase.verifyEqual(boundary.qCool_W, zeros(cfg.cell.count, 1), ...
                'AbsTol', 0);
        end

        function independentStoredEnergyMatchesConstantHeatInput(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 10;
            cfg.simulation.outputStep_s = 2;
            cfg.simulation.relativeTolerance = 1e-8;
            cfg.simulation.absoluteTolerance = 1e-10;
            cfg.controller.mode = 'openloop';
            cfg.boundary.conductance_W_per_K = 0;
            cfg.thermal.ambientConductance_W_per_K = 0;
            cfg.thermal.externalHeat_W = 0;
            cfg.electrical.entropicHeat = false;
            cfg.electrical.current_A = 5;
            cfg.electrical.alphaT_per_K = 0;
            cfg.electrical.alphaSOC = 0;
            cfg.cell.initialTemperature_K = linspace(297.5, 302.5, cfg.cell.count)';
            cfg.cell.thermalCapacity_J_per_K = linspace(30, 55, cfg.cell.count)';
            result = thermoweave.simulate(cfg);
            capacity = cfg.cell.thermalCapacity_J_per_K(:);
            measuredDelta_J = capacity' * ( ...
                result.state.temperature_K(end, :)' - ...
                result.state.temperature_K(1, :)');
            expectedDelta_J = cfg.cell.count * cfg.electrical.current_A^2 * ...
                cfg.electrical.R0_Ohm * cfg.simulation.duration_s;
            % This is independent of the solver RHS algebraic residual.
            testCase.verifyEqual(measuredDelta_J, expectedDelta_J, ...
                'AbsTol', 1e-3);
        end

        function rejectsNonphysicalInterfaceScaling(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.thermal.edgeConductanceScale = -1;
            testCase.verifyError(@() thermoweave.config.loadScenario(cfg), ...
                'thermoweave:config:Range');
            cfg = thermoweave.config.defaultConfig();
            cfg.boundary.coolant.cellConductanceScale = -0.1;
            testCase.verifyError(@() thermoweave.config.loadScenario(cfg), ...
                'thermoweave:config:Range');
        end

        function downsampleExportRetainsTerminalStateAndMatchingTimebase(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 5;
            cfg.simulation.outputStep_s = 1;
            cfg.controller.mode = 'openloop';
            result = thermoweave.simulate(cfg);
            exportPath = [tempname '.json'];
            manifest = thermoweave.results.exportJSON(result, exportPath, 2);
            testCase.addTeardown(@() delete(exportPath));
            payload = jsondecode(fileread(exportPath));
            testCase.verifyEqual(numel(payload.time_s), 4);
            testCase.verifyEqual(payload.time_s(end), result.time_s(end), ...
                'AbsTol', 0);
            testCase.verifyEqual(payload.metadata.timeBase_s(:), ...
                payload.time_s(:), 'AbsTol', 0);
            testCase.verifyEqual(payload.metadata.sourceSampleCount, ...
                numel(result.time_s));
            testCase.verifyEqual(manifest.sha256, ...
                thermoweave.util.hashText(fileread(exportPath)));
            testCase.verifyError(@() thermoweave.results.exportJSON( ...
                result, exportPath, 1.5), 'thermoweave:results:Downsample');
        end
    end
end
