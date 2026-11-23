classdef TestAnisotropicThermalGraph < matlab.unittest.TestCase
    % Independent transient oracle for a rectangular graph with unequal axes.
    properties (TestParameter)
        solver = {'ode45', 'ode15s'};
        scenario = struct( ...
            'mild', struct('scale', 1, 'minimumRatio', 80), ...
            'moderate', struct('scale', 30, 'minimumRatio', 2000), ...
            'stiff', struct('scale', 300, 'minimumRatio', 20000));
    end

    methods (TestClassSetup)
        function sourceOnPath(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            fixture = matlab.unittest.fixtures.PathFixture(fullfile(root, 'src'));
            testCase.applyFixture(fixture);
        end
    end

    methods (Test)
        function transposingTheGridPreservesNodeTrajectories(testCase, solver)
            cfg = testCase.rectangularConfig();
            cfg.simulation.solver = solver;

            order = [1 3 5 2 4 6];
            mapped = cfg;
            mapped.layout.rows = cfg.layout.columns;
            mapped.layout.columns = cfg.layout.rows;
            mapped.layout.gx_W_per_K = cfg.layout.gy_W_per_K;
            mapped.layout.gy_W_per_K = cfg.layout.gx_W_per_K;
            mapped.cell.thermalCapacity_J_per_K = cfg.cell.thermalCapacity_J_per_K(order);
            mapped.cell.initialTemperature_K = cfg.cell.initialTemperature_K(order);
            mapped.boundary.temperature_K = cfg.boundary.temperature_K(order);
            mapped.boundary.conductance_W_per_K = cfg.boundary.conductance_W_per_K(order);
            mapped.thermal.externalHeat_W = cfg.thermal.externalHeat_W(order);

            original = thermoweave.simulate(cfg);
            transposed = thermoweave.simulate(mapped);
            expected = testCase.thermalOracle(cfg, original.time_s);

            testCase.verifyEqual(original.time_s, (0:0.5:4)');
            testCase.verifyEqual(transposed.time_s, original.time_s);
            testCase.verifyEqual(original.state.temperature_K, expected, 'AbsTol', 1e-6);
            testCase.verifyEqual(transposed.state.temperature_K, expected(:, order), 'AbsTol', 1e-6);
            testCase.verifyEqual(transposed.state.temperature_K, ...
                original.state.temperature_K(:, order), 'AbsTol', 1e-6);
        end

        function toleranceSweepConvergesAcrossStiffness(testCase, solver, scenario)
            cfg = testCase.rectangularConfig();
            cfg.simulation.solver = solver;
            cfg.simulation.outputStep_s = 0.25;
            cfg.layout.gx_W_per_K = cfg.layout.gx_W_per_K * scenario.scale;
            cfg.layout.gy_W_per_K = cfg.layout.gy_W_per_K * scenario.scale;
            times = (0:0.25:4)';
            [expected, spectralRatio] = testCase.thermalOracle(cfg, times);
            relativeTolerances = [1e-3, 1e-6, 1e-9];
            [errors, residuals] = testCase.sweepTolerances( ...
                cfg, times, relativeTolerances, expected);

            testCase.verifyGreaterThan(spectralRatio, scenario.minimumRatio);
            testCase.verifyLessThan(errors(3), 2e-5);
            testCase.verifyLessThan(errors(3), errors(1));
            testCase.verifyLessThanOrEqual(errors(2), max(errors(1), 2e-5));
            testCase.verifyLessThanOrEqual(residuals(3), 1e-3);
            fprintf('TW_CONVERGENCE %s\n', jsonencode(struct( ...
                'solver', solver, 'scale', scenario.scale, ...
                'spectral_ratio', spectralRatio, 'relative_tolerances', relativeTolerances, ...
                'max_temperature_error_K', errors, 'normalized_energy_residual', residuals)));
        end
    end

    methods (Static, Access = private)
        function cfg = rectangularConfig()
            cfg = thermoweave.config.defaultConfig();
            cfg.layout.rows = 2;
            cfg.layout.columns = 3;
            cfg.layout.zoneCount = 1;
            cfg.layout.gx_W_per_K = 2;
            cfg.layout.gy_W_per_K = 5;
            cfg.cell.count = 6;
            cfg.cell.thermalCapacity_J_per_K = [12; 23; 34; 45; 56; 67];
            cfg.cell.initialTemperature_K = [306; 291; 311; 298; 325; 303];
            cfg.simulation.duration_s = 4;
            cfg.simulation.outputStep_s = 0.5;
            cfg.simulation.relativeTolerance = 1e-10;
            cfg.simulation.absoluteTolerance = 1e-11;
            cfg.controller.mode = 'openloop';
            cfg.electrical.current_A = 0;
            cfg.boundary.mode = 'vector';
            cfg.boundary.temperature_K = [280; 310; 295; 303; 301; 281];
            cfg.boundary.conductance_W_per_K = [0; 0.3; 0.6; 0.1; 0.9; 0.2];
            cfg.thermal.externalHeat_W = [2; 0; 5; 1; 4; 3];
        end

        function [errors, residuals] = sweepTolerances(cfg, times, relativeTolerances, expected)
            errors = zeros(size(relativeTolerances));
            residuals = zeros(size(relativeTolerances));
            for k = 1:numel(relativeTolerances)
                cfg.simulation.relativeTolerance = relativeTolerances(k);
                cfg.simulation.absoluteTolerance = relativeTolerances(k) * 1e-3;
                result = thermoweave.simulate(cfg);
                assert(isequal(result.time_s, times), 'Unexpected output time grid.');
                errors(k) = max(abs(result.state.temperature_K - expected), [], 'all');
                residuals(k) = result.energyLedger.normalizedResidual;
            end
        end

        function [temperatures, spectralRatio] = thermalOracle(cfg, times)
            % Write the six-node conductance matrix explicitly, independently
            % of the simulator's layout builder and edge accumulation.
            gx = cfg.layout.gx_W_per_K;
            gy = cfg.layout.gy_W_per_K;
            adjacency = [0 gy gx 0 0 0;
                         gy 0 0 gx 0 0;
                         gx 0 0 gy gx 0;
                         0 gx gy 0 0 gx;
                         0 0 gx 0 0 gy;
                         0 0 0 gx gy 0];
            capacity = diag(cfg.cell.thermalCapacity_J_per_K);
            boundary = cfg.boundary.conductance_W_per_K;
            decay = capacity \ (adjacency - diag(sum(adjacency, 2) + boundary));
            rates = abs(eig(decay));
            spectralRatio = max(rates) / min(rates);
            input = capacity \ (boundary .* cfg.boundary.temperature_K + cfg.thermal.externalHeat_W);
            system = [decay, input; zeros(1, 7)];
            initial = [cfg.cell.initialTemperature_K; 1];
            temperatures = zeros(numel(times), 6);
            for k = 1:numel(times)
                state = expm(system * times(k)) * initial;
                temperatures(k, :) = state(1:6)';
            end
        end
    end
end
