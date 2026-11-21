classdef TestScientificAuditGates < matlab.unittest.TestCase
    % Independent acceptance checks for the open ThermoWeave audit gates.
    methods (TestClassSetup)
        function sourceOnPath(testCase)
            root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'src')));
        end
    end
    methods (Test)
        function controlClockDoesNotFollowOutputSpacing(testCase)
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=5; cfg.simulation.outputStep_s=1;
            cfg.controller.samplePeriod_s=2;
            cfg.controller.rateLimit_per_s=0.1;
            cfg.cell.initialTemperature_K=350;
            cfg.boundary.temperature_K=350;
            cfg.thermal.ambientTemperature_K=350;
            cfg.electrical.current_A=0;
            result=thermoweave.simulate(cfg);
            command=result.control.zoneCommand(:,1);
            testCase.verifyEqual(result.time_s,(0:5)');
            testCase.verifyEqual(command(1:2),[0.2;0.2],'AbsTol',1e-12);
            testCase.verifyEqual(command(3:4),[0.4;0.4],'AbsTol',1e-12);
            testCase.verifyEqual(command(5:6),[0.6;0.6],'AbsTol',1e-12);
        end

        function faultBetweenOutputTimesHasExactHeatDuration(testCase)
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=2;cfg.simulation.outputStep_s=2;
            cfg.simulation.maxStep_s=0.05;
            cfg.controller.mode='openloop';
            cfg.cell.initialTemperature_K=298.15;
            cfg.thermal.ambientConductance_W_per_K=0;
            cfg.boundary.conductance_W_per_K=0;
            cfg.electrical.current_A=5;cfg.electrical.alphaT_per_K=0;
            cfg.electrical.alphaSOC=0;cfg.electrical.entropicHeat=false;
            cfg.faults.events=struct('type','heat_multiplier', ...
                'start_s',0.5,'end_s',1.5,'target',[], 'magnitude',3);
            result=thermoweave.simulate(cfg);
            C=cfg.cell.thermalCapacity_J_per_K;
            delta_J=sum(C*(result.state.temperature_K(end,:)- ...
                result.state.temperature_K(1,:)));
            base_W=cfg.cell.count*5^2*cfg.electrical.R0_Ohm;
            expected_J=base_W*(0.5+3*1+0.5);
            testCase.verifyEqual(delta_J,expected_J,'AbsTol',1e-4);
        end

        function signedIntegratedLedgerMatchesIndependentAdiabaticCase(testCase)
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=5;cfg.simulation.outputStep_s=1;
            cfg.controller.mode='openloop';
            cfg.thermal.ambientConductance_W_per_K=0;
            cfg.boundary.conductance_W_per_K=0;
            cfg.electrical.current_A=4;cfg.electrical.alphaT_per_K=0;
            cfg.electrical.alphaSOC=0;cfg.electrical.entropicHeat=false;
            result=thermoweave.simulate(cfg);
            testCase.verifyTrue(isfield(result,'energyLedger'));
            ledger=result.energyLedger;
            expected=cfg.cell.count*4^2*cfg.electrical.R0_Ohm*5;
            testCase.verifyEqual(ledger.generatedHeat_J,expected,'AbsTol',1e-3);
            testCase.verifyEqual(ledger.storedEnergyChange_J,expected,'AbsTol',1e-3);
            testCase.verifyEqual(ledger.ambientHeat_J,0,'AbsTol',1e-9);
            testCase.verifyEqual(ledger.coolantHeat_J,0,'AbsTol',1e-9);
            testCase.verifyLessThan(ledger.normalizedResidual,1e-4);
        end

        function canonicalHashIgnoresObjectFieldInsertionOrder(testCase)
            a=struct('z',2,'a',struct('high',3,'low',[1 2]));
            b=struct('a',struct('low',[1 2],'high',3),'z',2);
            first=thermoweave.util.hashCanonicalStruct(a);
            second=thermoweave.util.hashCanonicalStruct(b);
            testCase.verifyEqual(first,second);
            b.a.low(2)=9;
            testCase.verifyNotEqual(first,thermoweave.util.hashCanonicalStruct(b));
            testCase.verifyError(@() thermoweave.util.hashCanonicalStruct( ...
                struct('a',NaN)),'thermoweave:hash:Nonfinite');
        end

        function controllerExecutionIdentityIsRecorded(testCase)
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=4;
            cfg.simulation.outputStep_s=1;
            result=thermoweave.simulate(cfg);
            testCase.verifyTrue(isfield(result.control,'methodHistory'));
            testCase.verifyEqual(numel(result.control.methodHistory),numel(result.time_s));
            testCase.verifyTrue(all(string(result.control.methodHistory)== ...
                "baseline_bounded_controller"));
            testCase.verifyTrue(isfield(result.metadata,'scenarioCanonicalHash'));
            testCase.verifyEqual(numel(char(result.metadata.scenarioCanonicalHash)),64);
        end
        function signedBoundaryEnergyShowsNetCooling(testCase)
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=4;cfg.simulation.outputStep_s=2;
            cfg.controller.mode='openloop';cfg.electrical.current_A=0;
            cfg.cell.initialTemperature_K=330;
            cfg.boundary.temperature_K=298.15;
            cfg.boundary.conductance_W_per_K=0.25;
            result=thermoweave.simulate(cfg);
            ledger=result.energyLedger;
            testCase.verifyLessThan(ledger.ambientHeat_J,0);
            testCase.verifyEqual(ledger.generatedHeat_J,0,'AbsTol',1e-12);
            testCase.verifyLessThan(ledger.storedEnergyChange_J,0);
            testCase.verifyLessThan(ledger.normalizedResidual,5e-4);
        end

        function signedCoolantEnergyShowsNetCooling(testCase)
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=4;cfg.simulation.outputStep_s=2;
            cfg.controller.mode='openloop';cfg.electrical.current_A=0;
            cfg.cell.initialTemperature_K=330;
            cfg.thermal.ambientConductance_W_per_K=0;
            cfg.boundary.mode='coolant';
            result=thermoweave.simulate(cfg);
            ledger=result.energyLedger;
            testCase.verifyLessThan(ledger.coolantHeat_J,0);
            testCase.verifyEqual(ledger.ambientHeat_J,0,'AbsTol',1e-12);
            testCase.verifyLessThan(ledger.storedEnergyChange_J,0);
            testCase.verifyLessThan(ledger.normalizedResidual,5e-4);
        end

        function advancedExecutionMetadataCannotClaimUnexecutedQP(testCase)
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=1;cfg.simulation.outputStep_s=1;
            cfg.controller.mode='advanced';
            result=thermoweave.simulate(cfg);
            methods=string(result.control.methodHistory);
            objectives=result.control.objectiveHistory;
            advanced=(methods=="advanced_quadratic_program");
            if any(advanced)
                testCase.verifyTrue(all(isfinite(objectives(advanced))));
                testCase.verifyTrue(all(string(result.control.statusHistory(advanced))=="OPTIMAL"));
            end
            testCase.verifyTrue(all(methods=="advanced_quadratic_program" | ...
                methods=="baseline_fallback"));
            testCase.verifyTrue(all(isnan(objectives(~advanced))));
        end

        function numericCurrentProfileTransitionsAreIntegratedExactly(testCase)
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=3;
            cfg.simulation.outputStep_s=3;
            cfg.simulation.maxStep_s=0.05;
            cfg.controller.mode='openloop';
            cfg.electrical.current_A=0;
            cfg.electrical.currentProfile=[0;10;0;0];
            cfg.electrical.alphaT_per_K=0;
            cfg.electrical.alphaSOC=0;
            cfg.electrical.entropicHeat=false;
            cfg.boundary.conductance_W_per_K=0;
            cfg.thermal.ambientConductance_W_per_K=0;
            result=thermoweave.simulate(cfg);
            expected_J=cfg.cell.count*(10^2)*cfg.electrical.R0_Ohm*1;
            testCase.verifyEqual(result.energyLedger.generatedHeat_J, ...
                expected_J,'AbsTol',1e-4);
            testCase.verifyEqual(result.energyLedger.storedEnergyChange_J, ...
                expected_J,'AbsTol',1e-3);
        end

        function downsampledControlHistoriesAlignWithTimeVector(testCase)
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=5;
            cfg.simulation.outputStep_s=1;
            cfg.controller.samplePeriod_s=2;
            result=thermoweave.simulate(cfg);
            output=[tempname '.json'];
            testCase.addTeardown(@() delete(output));
            thermoweave.results.exportJSON(result,output,2);
            compact=jsondecode(fileread(output));
            expectedSamples=numel(compact.time_s);
            testCase.verifyEqual(expectedSamples,4);
            testCase.verifyEqual(numel(compact.control.methodHistory), ...
                expectedSamples);
            testCase.verifyEqual(numel(compact.control.statusHistory), ...
                expectedSamples);
            testCase.verifyEqual(numel(compact.control.objectiveHistory), ...
                expectedSamples);
        end


        function uniformCoolingMatchesIndependentAnalyticSolution(testCase)
            % Uniform no-current cooling is an independently soluble RC law.
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=12;
            cfg.simulation.outputStep_s=3;
            cfg.simulation.maxStep_s=0.25;
            cfg.simulation.relativeTolerance=1e-9;
            cfg.simulation.absoluteTolerance=1e-11;
            cfg.controller.mode='openloop';
            cfg.electrical.current_A=0;
            cfg.cell.initialTemperature_K=330;
            cfg.thermal.ambientTemperature_K=300;
            cfg.boundary.temperature_K=300;
            cfg.thermal.ambientConductance_W_per_K=0.2;
            cfg.boundary.conductance_W_per_K=0.3;
            decay=(0.2+0.3)/cfg.cell.thermalCapacity_J_per_K;
            for solverName=["ode15s" "ode45"]
                cfg.simulation.solver=char(solverName);
                result=thermoweave.simulate(cfg);
                expected=300+30*exp(-decay*result.time_s);
                deviations=abs(result.state.temperature_K-expected);
                testCase.verifyLessThan(max(deviations,[],'all'),1e-4);
                testCase.verifyLessThan(result.energyLedger.normalizedResidual,1e-3);
            end
        end

        function simultaneousCurrentAndOffGridHeatEventsConserveEnergy(testCase)
            % Direct piecewise integral of I^2*R times the fault multiplier.
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=3;
            cfg.simulation.outputStep_s=3;
            cfg.simulation.maxStep_s=0.05;
            cfg.controller.mode='openloop';
            cfg.electrical.current_A=0;
            cfg.electrical.currentProfile=struct('time_s',[0;1;2;3], ...
                'current_A',[2;4;0;0]);
            cfg.electrical.alphaT_per_K=0;
            cfg.electrical.alphaSOC=0;
            cfg.electrical.entropicHeat=false;
            cfg.boundary.conductance_W_per_K=0;
            cfg.thermal.ambientConductance_W_per_K=0;
            cfg.faults.events=struct('type','heat_multiplier', ...
                'start_s',0.5,'end_s',1.5,'target',[], 'magnitude',3);
            result=thermoweave.simulate(cfg);
            expectedPerCell_J=cfg.electrical.R0_Ohm*( ...
                2^2*(0.5+3*0.5)+4^2*(3*0.5+0.5));
            expectedTotal_J=cfg.cell.count*expectedPerCell_J;
            testCase.verifyEqual(result.energyLedger.generatedHeat_J, ...
                expectedTotal_J,'AbsTol',1e-4);
            testCase.verifyEqual(result.energyLedger.storedEnergyChange_J, ...
                expectedTotal_J,'AbsTol',1e-3);
            testCase.verifyLessThan(result.energyLedger.normalizedResidual,1e-4);
        end

    end
end
