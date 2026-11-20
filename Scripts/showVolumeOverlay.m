function figureHandle = showVolumeOverlay(volume, apex, hingePoints, sections, sectionThickness, figureTitle)

lineColor = [223 0 255] / 255; % #DF00FF pink
markerColor = [0 119 255] / 255; % #0077FF blue: about 5:1 contrast on black and 4:1 on white
lineWidth = 1.5;
dashPixels = [1.6 1.2];
numberOfPlanes = numel(sections.planeMasks);
geometry = discGeometry(apex, sections.layoutBase, numberOfPlanes);
centerPixel = geometry.centerPixel;
inPlaneDirections = [geometry.firstPerpendicular; geometry.secondPerpendicular];
borderColors = {'blue', 'red'};
leftViewWidth = floor(numberOfPlanes / 2);
viewTileStarts = [1, leftViewWidth + 1];
viewTileWidths = [leftViewWidth, numberOfPlanes - leftViewWidth];

figureHandle = figure('Visible', 'off');
figureHandle.Position(3:4) = [1600 900];
layout = tiledlayout(3, numberOfPlanes, 'TileSpacing', 'compact', 'Padding', 'compact');

for viewIndex = 1:2
    axesHandle = nexttile(viewTileStarts(viewIndex), [2 viewTileWidths(viewIndex)]);
    viewDirection = inPlaneDirections(viewIndex, :);
    imshow(extractObliqueSlice(volume, geometry.axisCenter, geometry.longAxisDirection, viewDirection, ...
        geometry.halfSize), []);
    hold on

    planeRows = geometry.planeRows(sections.tracedPlanes + 1);
    leftEdges = nan(size(sections.tracedPlanes));
    rightEdges = nan(size(sections.tracedPlanes));
    for listIndex = 1:numel(sections.tracedPlanes)
        if viewIndex == 1
            cavityPixels = find(sections.planeMasks{sections.tracedPlanes(listIndex)}(:, centerPixel));
        else
            cavityPixels = find(sections.planeMasks{sections.tracedPlanes(listIndex)}(centerPixel, :));
        end
        if ~isempty(cavityPixels)
            leftEdges(listIndex) = cavityPixels(1) - 0.5;
            rightEdges(listIndex) = cavityPixels(end) + 0.5;
        end
    end

    viewHinges = hingePoints(2 * viewIndex - [1 0], :);
    hingeRows = centerPixel + (viewHinges - geometry.axisCenter) * geometry.longAxisDirection';
    hingeColumns = centerPixel + (viewHinges - geometry.axisCenter) * viewDirection';
    [hingeColumns, order] = sort(hingeColumns);
    hingeRows = hingeRows(order);

    hasLeft = ~isnan(leftEdges);
    hasRight = ~isnan(rightEdges);
    capFractions = [0.05 0.15 0.3 0.5 0.75];
    capRows = geometry.planeRows(1) + capFractions * (planeRows(1) - geometry.planeRows(1));
    capLeft = centerPixel - (centerPixel - leftEdges(1)) * sqrt(capFractions);
    capRight = centerPixel + (rightEdges(1) - centerPixel) * sqrt(capFractions);
    if isnan(leftEdges(1)) || isnan(rightEdges(1))
        capRows = []; capLeft = []; capRight = [];
    end
    contourColumns = [hingeColumns(1), fliplr(leftEdges(hasLeft)), fliplr(capLeft), centerPixel, capRight, ...
        rightEdges(hasRight), hingeColumns(2)];
    contourRows = [hingeRows(1), fliplr(planeRows(hasLeft)), fliplr(capRows), geometry.planeRows(1), capRows, ...
        planeRows(hasRight), hingeRows(2)];
    arcLength = [0, cumsum(hypot(diff(contourColumns), diff(contourRows)))];
    [arcLength, unique_] = unique(arcLength);
    fineArc = linspace(0, arcLength(end), 400);
    plotDashed(interp1(arcLength, contourColumns(unique_), fineArc, 'makima'), ...
        interp1(arcLength, contourRows(unique_), fineArc, 'makima'), lineColor, lineWidth, dashPixels);

    for listIndex = find(hasLeft & hasRight)
        plotDashed([leftEdges(listIndex), rightEdges(listIndex)], planeRows(listIndex) * [1 1], lineColor, lineWidth, dashPixels);
    end
    plotDashed(hingeColumns, hingeRows, lineColor, lineWidth, dashPixels);
    axisBaseRow = interp1(hingeColumns, hingeRows, centerPixel, 'linear', 'extrap');
    plotDashed(centerPixel * [1 1], [geometry.planeRows(1), axisBaseRow], lineColor, lineWidth, dashPixels);
    plot(hingeColumns, hingeRows, '+', 'Color', markerColor, 'MarkerSize', 12, 'LineWidth', 2);
    plot(centerPixel, geometry.planeRows(1), '+', 'Color', markerColor, 'MarkerSize', 12, 'LineWidth', 2);
    addborder(axesHandle, borderColors{viewIndex}, 2);
    title(sprintf('Long axis view %d (%s)', viewIndex, borderColors{viewIndex}));
end

zoomLimits = centerPixel + [-0.6 0.6] * geometry.longAxisLength;
for planeIndex = 1:numberOfPlanes
    nexttile(2 * numberOfPlanes + planeIndex);
    imshow(extractObliqueSection(volume, geometry.planeCenters(planeIndex, :), ...
        geometry.firstPerpendicular, geometry.secondPerpendicular, geometry.halfSize, sectionThickness), []);
    hold on
    xlim(zoomLimits);
    ylim(zoomLimits);
    if ismember(planeIndex, sections.tracedPlanes)
        boundaries = bwboundaries(sections.planeMasks{planeIndex});
        for boundaryIndex = 1:numel(boundaries)
            plotDashed(boundaries{boundaryIndex}(:, 2)', boundaries{boundaryIndex}(:, 1)', lineColor, 1, dashPixels);
        end
        title({sprintf('Plane %d', planeIndex), sprintf('%.1f cm^2', sections.planeAreasSquareCm(planeIndex))}, 'FontSize', 8);
    else
        title({sprintf('Base (plane %d)', planeIndex), sprintf('hinges %.1f cm^2', sections.baseAreaSquareCm)}, 'FontSize', 8);
    end
end

title(layout, figureTitle);
drawnow
end

function plotDashed(columns, rows, color, lineWidth, dashPixels)
arcLength = [0, cumsum(hypot(diff(columns), diff(rows)))];
[arcLength, keep] = unique(arcLength);
if numel(arcLength) < 2
    return
end
samples = 0:0.2:arcLength(end);
sampleColumns = interp1(arcLength, columns(keep), samples);
sampleRows = interp1(arcLength, rows(keep), samples);
inGap = mod(samples, sum(dashPixels)) >= dashPixels(1);
sampleColumns(inGap) = NaN;
sampleRows(inGap) = NaN;
plot(sampleColumns, sampleRows, '-', 'Color', color, 'LineWidth', lineWidth);
end
