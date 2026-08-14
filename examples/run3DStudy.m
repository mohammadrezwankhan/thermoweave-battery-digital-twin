function result = run3DStudy()
%RUN3DSTUDY Run and render the synthetic ThermoWeave 3-D inter-cell study.

root = fileparts(fileparts(mfilename("fullpath")));
run(fullfile(root, "startup.m"));
scenario = fullfile(root, "config", "3d-intercell-study.json");
result = thermoweave.simulate(scenario);
thermoweave.visualization.render3DModule(result, "Visible", "on");
end
