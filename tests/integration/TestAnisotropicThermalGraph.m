classdef TestAnisotropicThermalGraph < matlab.unittest.TestCase
    % Independent transient oracle for a rectangular graph with unequal axes.
    properties (TestParameter)
        solver = {'ode45', 'ode15s'};
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
            cfg.simulation.solver = solver;
            cfg.simulation.relativeTolerance = 1e-10;
            cfg.simulation.absoluteTolerance = 1e-11;
            cfg.controller.mode = 'openloop';
            cfg.electrical.current_A = 0;
            cfg.boundary.mode = 'vector';
            cfg.boundary.temperature_K = [280; 310; 295; 303; 301; 281];
            cfg.boundary.conductance_W_per_K = [0; 0.3; 0.6; 0.1; 0.9; 0.2];
            cfg.thermal.externalHeat_W = [2; 0; 5; 1; 4; 3];

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
    end

    methods (Static, Access = private)
        function temperatures = thermalOracle(cfg, times)
            % Write the six-node conductance matrix explicitly, independently
            % of the simulator's layout builder and edge accumulation.
            adjacency = [0 5 2 0 0 0;
                         5 0 0 2 0 0;
                         2 0 0 5 2 0;
                         0 2 5 0 0 2;
                         0 0 2 0 0 5;
                         0 0 0 2 5 0];
            capacity = diag(cfg.cell.thermalCapacity_J_per_K);
            boundary = cfg.boundary.conductance_W_per_K;
            decay = capacity \ (adjacency - diag(sum(adjacency, 2) + boundary));
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
