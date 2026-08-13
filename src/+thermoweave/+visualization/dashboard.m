function app = dashboard(results, options)
%DASHBOARD Interactive, source-controlled ThermoWeave playback dashboard.
%   APP = DASHBOARD(RESULT) creates an accessible UI with play, pause,
%   scrub, frame export, animation export, scenario selection, and a
%   reduced-motion option. RESULTS can be a result structure or a cell array.

arguments
    results
    options.ReducedMotion (1, 1) logical = false
end

if ~iscell(results)
    results = {results};
end
validateResults(results);
names = cellfun(@(value) string(value.configuration.scenario.id), ...
    results, "UniformOutput", false);

app = struct;
app.Figure = uifigure("Name", "ThermoWeave thermal studio", ...
    "Color", [0.035 0.055 0.075], "Position", [80 80 1280 760]);
app.Figure.UserData = struct("results", {results}, "scenario", 1, ...
    "frame", 1, "playing", false, "reducedMotion", options.ReducedMotion);
grid = uigridlayout(app.Figure, [3 5]);
grid.RowHeight = {42, "1x", 54};
grid.ColumnWidth = {160, "1x", "1x", 145, 160};

app.Scenario = uidropdown(grid, "Items", string([names{:}]), ...
    "ValueChangedFcn", @changeScenario, "Tooltip", "Select scenario");
app.Scenario.Layout.Row = 1;
app.Scenario.Layout.Column = 1;
app.Status = uilabel(grid, "Text", "Ready", ...
    "FontColor", [0.78 0.88 0.9]);
app.Status.Layout.Row = 1;
app.Status.Layout.Column = [2 4];
app.ReducedMotion = uicheckbox(grid, "Text", "Reduced motion", ...
    "Value", options.ReducedMotion, "ValueChangedFcn", @changeMotion, ...
    "FontColor", [0.78 0.88 0.9]);
app.ReducedMotion.Layout.Row = 1;
app.ReducedMotion.Layout.Column = 5;

app.Heatmap = uiaxes(grid);
app.Heatmap.Layout.Row = 2;
app.Heatmap.Layout.Column = [1 2];
app.Traces = uiaxes(grid);
app.Traces.Layout.Row = 2;
app.Traces.Layout.Column = [3 5];

app.Play = uibutton(grid, "Text", "Play", ...
    "ButtonPushedFcn", @playAnimation, "Tooltip", "Play animation");
app.Play.Layout.Row = 3;
app.Play.Layout.Column = 1;
app.Slider = uislider(grid, "Limits", [1 numel(results{1}.time_s)], ...
    "Value", 1, "ValueChangingFcn", @scrub, "ValueChangedFcn", @scrub);
app.Slider.Layout.Row = 3;
app.Slider.Layout.Column = [2 3];
app.Export = uibutton(grid, "Text", "Export frame", ...
    "ButtonPushedFcn", @exportFrame, "Tooltip", "Export current PNG frame");
app.Export.Layout.Row = 3;
app.Export.Layout.Column = 4;
app.ExportAnimation = uibutton(grid, "Text", "Export animation", ...
    "ButtonPushedFcn", @exportGif, "Tooltip", "Export compact animated GIF");
app.ExportAnimation.Layout.Row = 3;
app.ExportAnimation.Layout.Column = 5;

app.Figure.KeyPressFcn = @keyboard;
drawFrame();

    function result = currentResult()
        data = app.Figure.UserData;
        result = data.results{data.scenario};
    end

    function drawFrame()
        data = app.Figure.UserData;
        result = currentResult();
        index = min(data.frame, numel(result.time_s));
        temperatureC = result.state.temperature_K(index, :) - 273.15;
        scatter(app.Heatmap, result.topology.x_m, result.topology.y_m, ...
            900, temperatureC, "filled", "MarkerEdgeColor", [0.85 0.95 1]);
        axis(app.Heatmap, "equal");
        grid(app.Heatmap, "on");
        colormap(app.Heatmap, turbo(256));
        title(app.Heatmap, sprintf("Thermal field — %.1f s", result.time_s(index)));
        xlabel(app.Heatmap, "x (m)");
        ylabel(app.Heatmap, "y (m)");
        envelope = result.state.temperature_K - 273.15;
        plot(app.Traces, result.time_s, max(envelope, [], 2), "LineWidth", 2);
        hold(app.Traces, "on");
        plot(app.Traces, result.time_s, mean(envelope, 2), "LineWidth", 1.5);
        plot(app.Traces, result.time_s, min(envelope, [], 2), "LineWidth", 1.2);
        xline(app.Traces, result.time_s(index), ":", "LineWidth", 1.5);
        hold(app.Traces, "off");
        grid(app.Traces, "on");
        xlabel(app.Traces, "Time (s)");
        ylabel(app.Traces, "Temperature (°C)");
        title(app.Traces, "Maximum / mean / minimum");
        app.Status.Text = sprintf("Frame %d/%d · peak %.2f °C · spread %.2f K", ...
            index, numel(result.time_s), max(temperatureC), ...
            max(temperatureC) - min(temperatureC));
        drawnow limitrate
    end

    function changeScenario(source, ~)
        data = app.Figure.UserData;
        data.scenario = find(string([names{:}]) == string(source.Value), 1);
        data.frame = 1;
        data.playing = false;
        app.Figure.UserData = data;
        result = currentResult();
        app.Slider.Limits = [1 numel(result.time_s)];
        app.Slider.Value = 1;
        drawFrame();
    end

    function changeMotion(source, ~)
        data = app.Figure.UserData;
        data.reducedMotion = source.Value;
        app.Figure.UserData = data;
    end

    function scrub(source, event)
        data = app.Figure.UserData;
        if isprop(event, "Value")
            data.frame = round(event.Value);
        else
            data.frame = round(source.Value);
        end
        app.Figure.UserData = data;
        drawFrame();
    end

    function playAnimation(~, ~)
        data = app.Figure.UserData;
        data.playing = ~data.playing;
        app.Figure.UserData = data;
        app.Play.Text = ternary(data.playing, "Pause", "Play");
        while isvalid(app.Figure) && app.Figure.UserData.playing
            data = app.Figure.UserData;
            result = currentResult();
            data.frame = mod(data.frame, numel(result.time_s)) + 1;
            app.Figure.UserData = data;
            app.Slider.Value = data.frame;
            drawFrame();
            if data.reducedMotion
                data.playing = false;
                app.Figure.UserData = data;
                app.Play.Text = "Play";
            else
                pause(0.06);
            end
        end
    end

    function exportFrame(~, ~)
        [file, folder] = uiputfile("*.png", "Export ThermoWeave frame", ...
            "thermoweave-frame.png");
        if isequal(file, 0)
            return
        end
        exportapp(app.Figure, fullfile(folder, file));
    end

    function exportGif(~, ~)
        [file, folder] = uiputfile("*.gif", "Export ThermoWeave animation", ...
            "thermoweave-animation.gif");
        if isequal(file, 0)
            return
        end
        app.Status.Text = "Exporting animation…";
        thermoweave.visualization.exportAnimation(currentResult(), ...
            fullfile(folder, file));
        drawFrame();
    end

    function keyboard(~, event)
        if event.Key == "space"
            playAnimation([], []);
        elseif event.Key == "rightarrow"
            app.Slider.Value = min(app.Slider.Limits(2), app.Slider.Value + 1);
            scrub(app.Slider, struct("Value", app.Slider.Value));
        elseif event.Key == "leftarrow"
            app.Slider.Value = max(1, app.Slider.Value - 1);
            scrub(app.Slider, struct("Value", app.Slider.Value));
        end
    end
end

function validateResults(results)
for index = 1:numel(results)
    if ~isstruct(results{index}) || ~isfield(results{index}, "schemaVersion") || ...
            string(results{index}.schemaVersion) ~= "thermoweave.result/v1"
        error("thermoweave:visualization:ResultSchema", ...
            "Every dashboard input must be a thermoweave.result/v1 structure.");
    end
end
end

function value = ternary(condition, trueValue, falseValue)
if condition
    value = trueValue;
else
    value = falseValue;
end
end
