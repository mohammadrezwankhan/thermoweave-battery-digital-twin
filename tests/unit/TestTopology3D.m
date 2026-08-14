classdef TestTopology3D < matlab.unittest.TestCase
    % Unit contracts for the deterministic 3-D graph-lattice extension.

    methods (TestClassSetup)
        function installSource(testCase)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, 'src')));
        end
    end

    methods (Test)
        function cuboidNodeAndSurfaceContracts(testCase)
            layout = struct('type', 'cuboid', 'rows', 3, 'columns', 4, ...
                'layers', 3, 'pitchX_m', 0.03, 'pitchY_m', 0.02, ...
                'pitchZ_m', 0.01, 'gx_W_per_K', 0.8, 'gy_W_per_K', 0.6, ...
                'gz_W_per_K', 0.25, 'zoneCount', 6);
            topology = thermoweave.thermal.buildTopology(layout);

            testCase.verifyEqual(topology.nodeCount, 36);
            testCase.verifyEqual(topology.edgeCount, 75);
            testCase.verifyEqual(topology.gridSize, [3 4 3]);
            testCase.verifyEqual(topology.layer(1), 1);
            testCase.verifyEqual(topology.layer(13), 2);
            testCase.verifyEqual(topology.layer(25), 3);
            testCase.verifyEqual(topology.z_m([1 13 25]), [0; 0.01; 0.02], ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(topology.surfaceMasks.zMin, ...
                [true(12, 1); false(24, 1)]);
            testCase.verifyEqual(topology.surfaceMasks.zMax, ...
                [false(24, 1); true(12, 1)]);
            testCase.verifyEqual(sum(topology.surfaceMasks.xMin), 9);
            testCase.verifyEqual(sum(topology.surfaceMasks.yMax), 12);
        end

        function conductanceAxesAndLaplacianArePhysical(testCase)
            layout = struct('type', 'cuboid', 'rows', 2, 'columns', 3, ...
                'layers', 2, 'gx_W_per_K', 0.8, 'gy_W_per_K', 0.6, ...
                'gz_W_per_K', 0.25, 'zoneCount', 3);
            topology = thermoweave.thermal.buildTopology(layout);
            axisLabels = string(topology.edgeAxis);
            laplacian = topology.laplacian_W_per_K;
            eigenvalues = eig((laplacian + laplacian') / 2);

            testCase.verifyEqual(sum(axisLabels == "x"), 8);
            testCase.verifyEqual(sum(axisLabels == "y"), 6);
            testCase.verifyEqual(sum(axisLabels == "z"), 6);
            testCase.verifyTrue(all(isfinite(topology.edgeConductance_W_per_K)));
            testCase.verifyTrue(all(topology.edgeConductance_W_per_K > 0));
            testCase.verifyEqual(laplacian, laplacian', 'AbsTol', 1e-12);
            testCase.verifyEqual(laplacian * ones(topology.nodeCount, 1), ...
                zeros(topology.nodeCount, 1), 'AbsTol', 1e-12);
            testCase.verifyGreaterThanOrEqual(min(eigenvalues), -1e-11);
        end

        function oneLayerCuboidReducesToLegacyRectangularTopology(testCase)
            legacyLayout = struct('type', 'rectangular', 'rows', 3, ...
                'columns', 4, 'pitchX_m', 0.03, 'pitchY_m', 0.02, ...
                'gx_W_per_K', 0.8, 'gy_W_per_K', 0.6, 'edgeConductance_W_per_K', 0.7, ...
                'zoneCount', 4);
            cuboidLayout = legacyLayout;
            cuboidLayout.type = 'cuboid';
            cuboidLayout.layers = 1;
            cuboidLayout.pitchZ_m = 0.01;
            cuboidLayout.gz_W_per_K = 0.25;
            legacy = thermoweave.thermal.buildTopology(legacyLayout);
            reduced = thermoweave.thermal.buildTopology(cuboidLayout);

            testCase.verifyEqual(reduced.nodeId, legacy.nodeId);
            testCase.verifyEqual(reduced.edges, legacy.edges);
            testCase.verifyEqual(reduced.edgeConductance_W_per_K, ...
                legacy.edgeConductance_W_per_K, 'AbsTol', 1e-12);
            testCase.verifyEqual(reduced.x_m, legacy.x_m, 'AbsTol', 1e-12);
            testCase.verifyEqual(reduced.y_m, legacy.y_m, 'AbsTol', 1e-12);
            testCase.verifyEqual(reduced.z_m, zeros(12, 1), 'AbsTol', 1e-12);
            testCase.verifyEqual(reduced.laplacian_W_per_K, ...
                legacy.laplacian_W_per_K, 'AbsTol', 1e-12);
        end
    end
end
