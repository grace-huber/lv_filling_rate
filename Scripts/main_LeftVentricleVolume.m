close all
setupWorkspace

dataset = resampleDicom(datasetFile);
voxelSize = dataset.widthspan / dataset.width; % cm per voxel, isotropic after resampling
if ~isempty(volumesToUse)
    dataset.data = dataset.data(:, :, :, volumesToUse + 1); % volume numbers start at 0
end
numberOfFrames = size(dataset.data, 4);

%% User input 1: LV center on the short axis view
results = struct();
if isfile(resultsFile)
    savedResults = load(resultsFile, 'results').results;
    for clickField = ["centerPoint", "hingePoints"]
        if isfield(savedResults, clickField)
            results.(clickField) = savedResults.(clickField);
        end
    end
end
if ~isfield(results, 'centerPoint')
    results.centerPoint = selectLeftVentricleCenter(dataset.data(:, :, :, 1));
    save(resultsFile, 'results');
end

[apexPoint, axisDirection] = findLongAxis(dataset.data, results.centerPoint, voxelSize);
results.apex = apexPoint;
results.axisDirection = axisDirection;

%% User input 2: mitral hinge points on two long axis views of every frame
if ~isfield(results, 'hingePoints') || size(results.hingePoints, 1) ~= numberOfFrames
    results.hingePoints = nan(numberOfFrames, 4, 3);
end
for frameNumber = find(any(isnan(results.hingePoints), [2 3]))'
    results.hingePoints(frameNumber, :, :) = selectMitralHinges(single(dataset.data(:, :, :, frameNumber)), ...
        apexPoint, axisDirection, voxelSize, sprintf('Frame %d of %d.', frameNumber, numberOfFrames));
    save(resultsFile, 'results');
end

overlayFolder = fullfile(outputFolder, 'VolumeOverlays');
if ~isfolder(overlayFolder)
    mkdir(overlayFolder);
end
overlayVideo = VideoWriter(fullfile(overlayFolder, 'VolumeOverlay.mp4'), 'MPEG-4');
overlayVideo.FrameRate = overlayFramesPerSecond;
open(overlayVideo);
results.volumeMilliliters = zeros(numberOfFrames, 1);
results.planeAreasSquareCm = zeros(numberOfFrames, numberOfSections); % last column: base ellipse
for frameNumber = 1:numberOfFrames
    volume = single(dataset.data(:, :, :, frameNumber));
    hingePoints = squeeze(results.hingePoints(frameNumber, :, :));
    [results.volumeMilliliters(frameNumber), sections] = calculateLeftVentricleVolume(volume, apexPoint, ...
        axisDirection, hingePoints, numberOfSections, voxelSize, sectionThicknessCm);
    results.planeAreasSquareCm(frameNumber, :) = [sections.planeAreasSquareCm(1:end - 1), sections.baseAreaSquareCm];

    overlayFigure = showVolumeOverlay(volume, apexPoint, hingePoints, sections, sectionThicknessCm / voxelSize, ...
        sprintf('%s frame %d: LV volume = %.1f mL (%d sections, compact wall, base at the mitral hinge points)', ...
        datasetName, frameNumber, results.volumeMilliliters(frameNumber), numberOfSections));
    exportgraphics(overlayFigure, fullfile(overlayFolder, sprintf('Frame%02d_VolumeOverlay.png', frameNumber)));
    overlayImage = frame2im(getframe(overlayFigure));
    if frameNumber == 1
        videoFrameSize = size(overlayImage, [1 2]);
    end
    writeVideo(overlayVideo, imresize(overlayImage, videoFrameSize));
    close(overlayFigure);
    fprintf('%s frame %d: %.1f mL\n', datasetName, frameNumber, results.volumeMilliliters(frameNumber));
end
close(overlayVideo);
save(resultsFile, 'results');

%% Volume and dV/dt curves, with the reference volumes if there are any
frameNumbers = (1:numberOfFrames)';
timeSeconds = (frameNumbers - 1) / volumesPerSecond;
writetable(table(frameNumbers, timeSeconds, results.volumeMilliliters, 'VariableNames', ...
    {'Frame', 'TimeSeconds', 'VolumeMilliliters'}), fullfile(outputFolder, 'LeftVentricleVolumes.csv'));

curveNames = "This method";
volumesMilliliters = results.volumeMilliliters;
referenceFile = fullfile(outputFolder, 'MachineVolumes.csv');
if isfile(referenceFile)
    referenceTable = readtable(referenceFile);
    curveNames = ["Reference", curveNames];
    volumesMilliliters = [referenceTable.VolumeMilliliters(frameNumbers), volumesMilliliters];
end
numberOfCurves = numel(curveNames);

curveMetrics = cell(1, numberOfCurves);
for curveIndex = 1:numberOfCurves
    curveMetrics{curveIndex} = discrete_filling_rate([timeSeconds, volumesMilliliters(:, curveIndex)], false);
end
fillingRates = cell2mat(cellfun(@(metrics) metrics.dVdt, curveMetrics, 'UniformOutput', false));
rateFrames = frameNumbers(1:end - 1) + 0.5;
toFrame = @(seconds) seconds * volumesPerSecond + 1;
summaryTable = table(curveNames', cellfun(@(m) m.EDV, curveMetrics)', cellfun(@(m) toFrame(m.t_EDV), curveMetrics)', ...
    cellfun(@(m) m.ESV, curveMetrics)', cellfun(@(m) toFrame(m.t_ESV), curveMetrics)', cellfun(@(m) m.SV, curveMetrics)', ...
    cellfun(@(m) m.EF, curveMetrics)', cellfun(@(m) m.PER, curveMetrics)', cellfun(@(m) m.PER / m.EDV, curveMetrics)', ...
    cellfun(@(m) toFrame(m.t_PER), curveMetrics)', cellfun(@(m) m.PFR, curveMetrics)', ...
    cellfun(@(m) m.PFR / m.EDV, curveMetrics)', cellfun(@(m) toFrame(m.t_PFR), curveMetrics)', ...
    'VariableNames', {'Curve', 'EDV_mL', 'EDFrame', 'ESV_mL', 'ESFrame', 'SV_mL', 'EF_percent', 'PeakEjection_mLps', ...
    'PeakEjection_EDVps', 'PeakEjectionFrame', 'PeakFilling_mLps', 'PeakFilling_EDVps', 'PeakFillingFrame'});
disp(summaryTable)
writetable(summaryTable, fullfile(outputFolder, 'LeftVentricleVolumeSummary.csv'));
ejectionFractions = summaryTable.EF_percent';
if numberOfCurves == 2
    differences = volumesMilliliters(:, 2) - volumesMilliliters(:, 1);
    fprintf('This method minus reference: bias %+.1f mL, limits of agreement +/-%.1f mL, mean |difference| %.1f mL\n', ...
        mean(differences), 1.96 * std(differences), mean(abs(differences)));
end

curveColors = [0.25 0.25 0.25; hex2rgb("#1c5cab")];
curveColors = curveColors(end - numberOfCurves + 1:end, :);
volumeFigure = figure(1); clf
theme(volumeFigure, 'light');
set(volumeFigure, 'Position', [100 100 900 750], 'Color', 'w');
layout = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
panelData = {frameNumbers, volumesMilliliters, 'LV volume (mL)'; rateFrames, fillingRates, 'dV/dt (mL/s)'};
for panelIndex = 1:2
    panelAxes = nexttile(layout);
    hold(panelAxes, 'on');
    if panelIndex == 2
        yline(panelAxes, 0, '-', 'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');
    end
    for curveIndex = 1:numberOfCurves
        if curveNames(curveIndex) == "Reference"
            lineStyle = {'LineWidth', 3, 'Marker', 'none'};
        else
            lineStyle = {'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', curveColors(curveIndex, :), ...
                'MarkerEdgeColor', 'w'};
        end
        plot(panelAxes, panelData{panelIndex, 1}, panelData{panelIndex, 2}(:, curveIndex), '-', 'Color', curveColors(curveIndex, :), ...
            lineStyle{:}, 'DisplayName', sprintf('%s: EF %.0f%%', curveNames(curveIndex), ejectionFractions(curveIndex)));
    end
    grid(panelAxes, 'on');
    set(panelAxes, 'Box', 'off', 'GridColor', [0.85 0.85 0.85], 'GridAlpha', 1, 'FontSize', 12);
    xlim(panelAxes, [1 numberOfFrames]);
    ylabel(panelAxes, panelData{panelIndex, 3});
    if panelIndex == 1
        curveLegend = legend(panelAxes, 'Orientation', 'horizontal', 'Box', 'off');
        curveLegend.Layout.Tile = 'north';
    end
end
xlabel(panelAxes, 'Frame number');
title(layout, sprintf('%s: LV volume (compact wall, curved wall, base at the mitral hinge points)', datasetName), ...
    'Interpreter', 'none', 'FontSize', 14);
exportgraphics(volumeFigure, fullfile(outputFolder, 'LeftVentricleVolume.png'));
