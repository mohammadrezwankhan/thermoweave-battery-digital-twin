function path = createSocialPreview()
%CREATESOCIALPREVIEW Create a deterministic data-driven preview fallback.
%   A separately generated project-owned image can replace this fallback
%   after provenance review. This function never copies external imagery.

root = fileparts(fileparts(mfilename("fullpath")));
result = runDemo();
figureHandle = thermoweave.visualization.renderFigure(result, Visible="off");
figureHandle.Position(3:4) = [1200 630];
path = fullfile(root, "docs", "assets", "social-preview.png");
exportgraphics(figureHandle, path, "Resolution", 120);
close(figureHandle);
end
