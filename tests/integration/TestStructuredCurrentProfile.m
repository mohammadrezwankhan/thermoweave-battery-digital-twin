classdef TestStructuredCurrentProfile < matlab.unittest.TestCase
    properties (TestParameter)
        solver = {'ode15s','ode45'};
    end

    methods (TestClassSetup)
        function sourceOnPath(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'src')));
        end
    end

    methods (Test)
        function singleKnotIsAConstantProfile(testCase,solver)
            cfg = adiabaticConfig(solver);
            cfg.electrical.current_A = -4;
            constant = thermoweave.simulate(cfg);
            cfg.electrical.current_A = 9;
            cfg.electrical.currentProfile = struct('time_s',0.37,'current_A',-4);
            profiled = thermoweave.simulate(cfg);

            testCase.verifyEqual(profiled.signals.current_A,constant.signals.current_A);
            testCase.verifyEqual(profiled.state,constant.state);
            testCase.verifyEqual(profiled.energyLedger,constant.energyLedger);
        end

        function chargeRestAndDischargeMatchClosedForm(testCase,solver)
            cfg = adiabaticConfig(solver);
            cfg.electrical.currentProfile = struct( ...
                'time_s',[0; 0.37; 1.23; 1.71],'current_A',[7; -4; 0; 3]);
            r = thermoweave.simulate(cfg);

            sampleTimes = [0; 0.5; 1; 1.5; 2; 2.5; 2.6];
            testCase.verifyEqual(r.time_s,sampleTimes,'AbsTol',1e-12);
            [temperature,soc,current,heat] = closedForm(sampleTimes,cfg);
            n = cfg.cell.count;
            testCase.verifyEqual(r.state.temperature_K,repmat(temperature,1,n),'AbsTol',2e-6);
            testCase.verifyEqual(r.state.soc,repmat(soc,1,n),'AbsTol',2e-9);
            testCase.verifyEqual(r.signals.current_A,current);
            testCase.verifyEqual(r.signals.heatGeneration_W,repmat(heat,1,n),'AbsTol',4e-9);
            expectedEnergy = n * cfg.cell.thermalCapacity_J_per_K * (temperature(end)-temperature(1));
            testCase.verifyEqual(r.energyLedger.generatedHeat_J,expectedEnergy,'AbsTol',2e-5);
            testCase.verifyEqual(r.energyLedger.storedEnergyChange_J,expectedEnergy,'AbsTol',2e-5);
        end
    end
end

function cfg = adiabaticConfig(solver)
cfg = thermoweave.config.defaultConfig();
cfg.simulation.solver = solver;
cfg.simulation.duration_s = 2.6;
cfg.simulation.outputStep_s = 0.5;
cfg.simulation.maxStep_s = 0.04;
cfg.simulation.relativeTolerance = 1e-10;
cfg.simulation.absoluteTolerance = 1e-12;
cfg.controller.mode = 'openloop';
cfg.thermal.ambientConductance_W_per_K = 0;
cfg.boundary.conductance_W_per_K = 0;
cfg.electrical.alphaT_per_K = 0;
cfg.electrical.alphaSOC = 0;
cfg.electrical.entropicHeat = true;
cfg.electrical.dUoc_dT_V_per_K = 0.001;
cfg.electrical.chargeEfficiency = 0.86;
cfg.electrical.dischargeEfficiency = 0.92;
end

function [temperature,soc,current,heat] = closedForm(times,cfg)
knots = [0; 0.37; 1.23; 1.71; 2.6];
currents = [7; -4; 0; 3];
C = cfg.cell.thermalCapacity_J_per_K;
R = cfg.electrical.R0_Ohm;
dUdT = cfg.electrical.dUoc_dT_V_per_K;
Q = cfg.electrical.capacity_C;
temperature = repmat(cfg.cell.initialTemperature_K,size(times));
soc = repmat(cfg.cell.initialSOC,size(times));
for phase = [1 2 4] % The current-free interval leaves both states unchanged.
    I = currents(phase);
    dt = max(0,min(times,knots(phase+1))-knots(phase));
    rate = -I*dUdT/C;
    steadyTemperature = I*R/dUdT;
    temperature = temperature+(temperature-steadyTemperature).*expm1(rate*dt);
    if I > 0
        soc = soc-I*dt/(Q*cfg.electrical.dischargeEfficiency);
    else
        soc = soc-I*dt*cfg.electrical.chargeEfficiency/Q;
    end
end
current = [7; -4; -4; 0; 3; 3; 3];
heat = R*current.^2-dUdT*current.*temperature;
end
