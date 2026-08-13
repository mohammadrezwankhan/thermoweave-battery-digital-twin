classdef TestConfigAndPhysics < matlab.unittest.TestCase
    % Unit contracts for validation, topology, electrical and coolant APIs.

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
        function rejectsInvalidCellDimensions(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.cell.count = cfg.cell.count + 1;
            testCase.verifyError(@() thermoweave.config.loadScenario(cfg), ...
                'thermoweave:config:Dimension');
        end

        function rejectsNegativeThermalMass(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.cell.thermalCapacity_J_per_K = -1;
            testCase.verifyError(@() thermoweave.config.loadScenario(cfg), ...
                'thermoweave:config:Range');
        end

        function rejectsInvalidConductance(testCase)
            cfg = thermoweave.config.defaultConfig();
            layout = cfg.layout;
            layout.gx_W_per_K = 0;
            testCase.verifyError(@() thermoweave.thermal.buildTopology(layout), ...
                'thermoweave:topology:Conductance');
        end

        function rejectsUnsupportedBoundaryMode(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.boundary.mode = 'unsupported';
            testCase.verifyError(@() thermoweave.config.loadScenario(cfg), ...
                'thermoweave:config:Boundary');
        end

        function rejectsUnsafeCoolantAndElectricalValues(testCase)
            negativeFlow = thermoweave.config.defaultConfig();
            negativeFlow.boundary.coolant.massFlow_kg_per_s = -0.01;
            zeroEfficiency = thermoweave.config.defaultConfig();
            zeroEfficiency.electrical.dischargeEfficiency = 0;
            testCase.verifyError(@() thermoweave.config.loadScenario(negativeFlow), ...
                'thermoweave:config:Range');
            testCase.verifyError(@() thermoweave.config.loadScenario(zeroEfficiency), ...
                'thermoweave:config:Range');
        end

        function rejectsNonfiniteAndMalformedFaultDeclarations(testCase)
            nonfinite = thermoweave.config.defaultConfig();
            nonfinite.cell.initialTemperature_K = NaN;
            malformed = thermoweave.config.defaultConfig();
            malformed.faults.events = struct('type', 'sensor_bias', ...
                'start_s', 5, 'end_s', 2, 'target', 1, 'magnitude', 2);
            invalidTarget = thermoweave.config.defaultConfig();
            invalidTarget.faults.events = struct('type', 'heat_multiplier', ...
                'start_s', 0, 'end_s', 2, 'target', 'bogus', 'magnitude', 2);
            testCase.verifyError(@() thermoweave.config.loadScenario(nonfinite), ...
                'thermoweave:config:Range');
            testCase.verifyError(@() thermoweave.config.loadScenario(malformed), ...
                'thermoweave:config:Fault');
            testCase.verifyError(@() thermoweave.config.loadScenario(invalidTarget), ...
                'thermoweave:config:Fault');
        end

        function rejectsUnknownConfigurationSchema(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.schemaVersion = 'thermoweave.config/v9';
            testCase.verifyError(@() thermoweave.config.loadScenario(cfg), ...
                'thermoweave:config:Schema');
        end

        function topologyContractAndPermutationMetadata(testCase)
            cfg = thermoweave.config.defaultConfig();
            topology = thermoweave.thermal.buildTopology(cfg.layout);
            nodeCount = cfg.cell.count;
            testCase.verifyEqual(topology.nodeId, (1:nodeCount)');
            testCase.verifyEqual(sort(topology.channelOrder), (1:nodeCount)');
            testCase.verifyEqual(size(topology.edges, 2), 2);
            testCase.verifyTrue(all(topology.edges(:, 1) < topology.edges(:, 2)));
            testCase.verifyTrue(all(topology.edgeConductance_W_per_K > 0));
            testCase.verifyEqual(topology.nodeCount, nodeCount);
        end

        function jouleAndEntropicHeatSigns(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.electrical.entropicHeat = true;
            temperature = repmat(cfg.cell.initialTemperature_K, cfg.cell.count, 1);
            soc = repmat(cfg.cell.initialSOC, cfg.cell.count, 1);
            current = repmat(5, cfg.cell.count, 1);
            [heat, details] = thermoweave.electrical.heatGeneration(temperature, soc, current, cfg);
            testCase.verifyTrue(all(details.joule_W > 0));
            testCase.verifyTrue(all(details.entropic_W < 0));
            testCase.verifyEqual(heat, details.joule_W + details.entropic_W, 'AbsTol', 1e-12);
        end

        function socDerivativeHonorsChargeAndDischarge(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.electrical.dischargeEfficiency = 0.9;
            cfg.electrical.chargeEfficiency = 0.8;
            soc = [0.8; 0.8];
            current = [9; -9];
            dz = thermoweave.electrical.socDerivative(soc, current, cfg);
            testCase.verifyLessThan(dz(1), 0);
            testCase.verifyGreaterThan(dz(2), 0);
            testCase.verifyEqual(dz(1), -9 / (0.9 * cfg.electrical.capacity_C), 'AbsTol', 1e-15);
            testCase.verifyEqual(dz(2), 9 * 0.8 / cfg.electrical.capacity_C, 'AbsTol', 1e-15);
        end

        function coolantForwardAndReversePatternConserveHeat(testCase)
            temperature = [300; 301; 302; 303];
            conductance = 2 * eye(4);
            inlet = 298.15;
            flow = 0.01;
            heatCapacity = 3800;
            [forwardTemperature, forwardHeat] = thermoweave.coolant.march( ...
                temperature, conductance, inlet, flow, heatCapacity);
            [reverseTemperature, reverseHeat] = thermoweave.coolant.march( ...
                flipud(temperature), fliplr(conductance), inlet, flow, heatCapacity);
            testCase.verifyEqual(sum(forwardHeat), flow * heatCapacity * (forwardTemperature(end) - inlet), 'AbsTol', 1e-9);
            testCase.verifyEqual(sum(reverseHeat), flow * heatCapacity * (reverseTemperature(end) - inlet), 'AbsTol', 1e-9);
            testCase.verifyTrue(all(forwardHeat > 0));
        end

        function coolantRestrictionTargetsOnlyDeclaredSegment(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.boundary.mode = 'coolant';
            cfg.faults.events = struct('type', 'coolant_blockage', ...
                'start_s', 10, 'end_s', 20, 'target', 2, 'magnitude', 0.2);
            topology = thermoweave.thermal.buildTopology(cfg.layout);
            temperature = repmat(300, cfg.cell.count, 1);
            before = thermoweave.coolant.evaluate(temperature, cfg, topology, [], 0);
            active = thermoweave.coolant.evaluate(temperature, cfg, topology, [], 15);
            testCase.verifyEqual(active.Hcool_W_per_K(:, 2), ...
                0.2 * before.Hcool_W_per_K(:, 2), 'AbsTol', 1e-12);
            testCase.verifyEqual(active.Hcool_W_per_K(:, [1 3 4]), ...
                before.Hcool_W_per_K(:, [1 3 4]), 'AbsTol', 1e-12);
        end

        function coolantSupportsPerSegmentConductance(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.boundary.mode = 'coolant';
            cfg.boundary.coolant.segmentConductance_W_per_K = [1; 2; 3; 4];
            topology = thermoweave.thermal.buildTopology(cfg.layout);
            boundary = thermoweave.coolant.evaluate( ...
                repmat(300, cfg.cell.count, 1), cfg, topology, [], 0);
            testCase.verifyEqual(sum(boundary.Hcool_W_per_K, 1), ...
                [3 6 9 12], 'AbsTol', 1e-12);
        end

        function variabilityIncludesAllDeclaredThermalInterfaces(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.variability.enabled = true;
            [varied, info] = thermoweave.uncertainty.applyVariability(cfg, 42);
            topology = thermoweave.thermal.buildTopology(cfg.layout);
            testCase.verifyTrue(info.enabled);
            testCase.verifySize(varied.thermal.edgeConductanceScale, ...
                [topology.edgeCount 1]);
            testCase.verifySize(varied.boundary.coolant.cellConductanceScale, ...
                [cfg.cell.count 1]);
            testCase.verifyNotEqual(varied.thermal.edgeConductanceScale, ...
                ones(topology.edgeCount, 1));
        end

        function scalarAndUniformVectorBoundaryAreEquivalent(testCase)
            cfgScalar = thermoweave.config.defaultConfig();
            cfgScalar.simulation.duration_s = 4;
            cfgScalar.simulation.outputStep_s = 1;
            cfgScalar.electrical.current_A = 0;
            cfgVector = cfgScalar;
            cfgVector.boundary.mode = 'vector';
            cfgVector.boundary.temperature_K = repmat(cfgScalar.boundary.temperature_K, cfgScalar.cell.count, 1);
            cfgVector.boundary.conductance_W_per_K = repmat(cfgScalar.boundary.conductance_W_per_K, cfgScalar.cell.count, 1);
            scalarResult = thermoweave.simulate(cfgScalar);
            vectorResult = thermoweave.simulate(cfgVector);
            testCase.verifyEqual(scalarResult.state.temperature_K, vectorResult.state.temperature_K, 'AbsTol', 1e-10);
            testCase.verifyEqual(scalarResult.state.soc, vectorResult.state.soc, 'AbsTol', 1e-12);
        end

        function scalarCurrentProfileActsAsConstant(testCase)
            cfg = thermoweave.config.defaultConfig();
            cfg.simulation.duration_s = 2;
            cfg.simulation.outputStep_s = 1;
            cfg.electrical.currentProfile = 3;
            result = thermoweave.simulate(cfg);
            testCase.verifyEqual(result.signals.current_A, ...
                repmat(3, numel(result.time_s), 1), 'AbsTol', 0);
        end
    end
end
