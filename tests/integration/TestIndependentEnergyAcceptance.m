classdef TestIndependentEnergyAcceptance < matlab.unittest.TestCase
    % A legacy same-RHS zero is not sufficient scientific energy evidence.
    methods (TestClassSetup)
        function sourceOnPath(testCase)
            root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'src')));
        end
    end
    methods (Test)
        function independentEndpointAndSignedSourcesPass(testCase)
            result=adiabaticSample();
            testCase.verifyTrue(thermoweave.validation.hasIndependentEnergyBalance( ...
                result,1e-3));
        end

        function rejectComplexInputsAndNonvectorCapacity(testCase)
            r=adiabaticSample();
            verify=@(result,tol) thermoweave.validation.hasIndependentEnergyBalance(result,tol);
            testCase.verifyFalse(verify(r,1e-3+1i));
            bad=r;
            bad.state.temperature_K=r.state.temperature_K+1i;
            testCase.verifyFalse(verify(bad,1e-3));
            bad=r;
            bad.configuration.cell.thermalCapacity_J_per_K= ...
                r.configuration.cell.thermalCapacity_J_per_K+1i;
            testCase.verifyFalse(verify(bad,1e-3));
            for key=fieldnames(r.energyLedger)'
                name=key{1};
                if ismember(name,{'generatedHeat_J','ambientHeat_J','coolantHeat_J', ...
                        'externalHeat_J','netHeat_J','storedEnergyChange_J','normalizedResidual'})
                    bad=r;
                    bad.energyLedger.(name)=bad.energyLedger.(name)+1e-12i;
                    testCase.verifyFalse(verify(bad,1e-3),name);
                end
            end
            n=size(r.state.temperature_K,2);
            cap=r.configuration.cell.thermalCapacity_J_per_K;
            if isscalar(cap),cap=repmat(cap,n,1);end
            r.configuration.cell.thermalCapacity_J_per_K=reshape(cap,2,[]);
            testCase.verifyFalse(verify(r,1e-3));
        end

        function forgedLegacyZeroCannotHideIncorrectHeat(testCase)
            result=adiabaticSample();
            result.energyResidualNormalized=0; % Legacy same-RHS identity.
            result.energyLedger.generatedHeat_J= ...
                result.energyLedger.generatedHeat_J+10;
            testCase.verifyFalse(thermoweave.validation.hasIndependentEnergyBalance( ...
                result,1e-3));
        end

        function malformedOrContradictorySignedLedgerIsRejected(testCase)
            result=adiabaticSample();
            result.energyLedger.netHeat_J=result.energyLedger.netHeat_J+100;
            testCase.verifyFalse(thermoweave.validation.hasIndependentEnergyBalance( ...
                result,1e-3));
            result=adiabaticSample();
            result.energyLedger.coolantHeat_J=NaN;
            testCase.verifyFalse(thermoweave.validation.hasIndependentEnergyBalance( ...
                result,1e-3));
        end
        function coolantEnergyResidualConvergesUnderRefinement(testCase)
            cfg=thermoweave.config.defaultConfig();
            cfg.simulation.duration_s=20;
            cfg.simulation.outputStep_s=2;
            cfg.controller.mode='openloop';
            cfg.electrical.current_A=0;
            cfg.boundary.mode='coolant';
            cfg.cell.initialTemperature_K=linspace(299,304,cfg.cell.count)';
            topo=thermoweave.thermal.buildTopology(cfg.layout);
            cfg.boundary.coolant.segmentNodes=topo.zoneId;
            cfg.simulation.maxStep_s=0.25;
            coarse=thermoweave.simulate(cfg);
            cfg.simulation.maxStep_s=0.1;
            fine=thermoweave.simulate(cfg);
            testCase.verifyLessThan(fine.energyLedger.normalizedResidual, ...
                coarse.energyLedger.normalizedResidual);
            testCase.verifyTrue(thermoweave.validation.hasIndependentEnergyBalance( ...
                fine,1e-3));
        end
    end
end

function result=adiabaticSample()
cfg=thermoweave.config.defaultConfig();
cfg.simulation.duration_s=4;
cfg.simulation.outputStep_s=2;
cfg.simulation.maxStep_s=0.1;
cfg.controller.mode='openloop';
cfg.electrical.current_A=3;
cfg.electrical.alphaT_per_K=0;
cfg.electrical.alphaSOC=0;
cfg.electrical.entropicHeat=false;
cfg.thermal.ambientConductance_W_per_K=0;
cfg.boundary.conductance_W_per_K=0;
result=thermoweave.simulate(cfg);
end
