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
