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
    end
end
