function cavityMasks = segmentShortAxisDiscs(volume, apex, base, numberOfPlanes, voxelSize, sectionThicknessCm)

minimumAreaRatio = 0.25;
maximumAspectRatio = 1.75;
maximumSpikeRatio = 1.3;

geometry = discGeometry(apex, base, numberOfPlanes);
imageSize = 2 * geometry.halfSize + 1;
contours = cell(1, numberOfPlanes);
for planeIndex = 1:numberOfPlanes
    shortAxisImage = extractObliqueSection(volume, geometry.planeCenters(planeIndex, :), ...
        geometry.firstPerpendicular, geometry.secondPerpendicular, geometry.halfSize, sectionThicknessCm / voxelSize);
    shortAxisImage = flattenBrightness(shortAxisImage, geometry.centerPixel, 0.5 * geometry.longAxisLength);
    contour = segmentCavity(shortAxisImage, geometry.centerPixel, 0.5 * geometry.longAxisLength, voxelSize, true);
    if polyarea(contour(:, 1), contour(:, 2)) > 0
        hullIndices = convhull(contour(:, 1), contour(:, 2));
        contour = contour(hullIndices(1:end - 1), :);
    end
    if planeIndex > 1
        areaRatio = polyarea(contour(:, 1), contour(:, 2)) ...
            / polyarea(contours{planeIndex - 1}(:, 1), contours{planeIndex - 1}(:, 2));
        outlineSpread = eig(cov(contour));
        aspectRatio = sqrt(max(outlineSpread) / min(outlineSpread));
        if areaRatio < minimumAreaRatio || aspectRatio > maximumAspectRatio
            contour = contours{planeIndex - 1};
        end
    end
    contours{planeIndex} = contour;
end

planeAreas = cellfun(@(contour) polyarea(contour(:, 1), contour(:, 2)), contours);
for planeIndex = 2:numberOfPlanes - 1
    [largerNeighborArea, neighborOffset] = max(planeAreas(planeIndex + [-1 1]));
    if planeAreas(planeIndex) > maximumSpikeRatio * largerNeighborArea
        contours{planeIndex} = contours{planeIndex + 2 * neighborOffset - 3};
        planeAreas(planeIndex) = largerNeighborArea;
    end
end
% The base plane has one neighbor: an outline leaking through the open mitral valve reuses the plane below it
if planeAreas(end) > maximumSpikeRatio * planeAreas(end - 1)
    contours{end} = contours{end - 1};
end

cavityMasks = cellfun(@(contour) poly2mask(contour(:, 1), contour(:, 2), imageSize, imageSize), contours, ...
    'UniformOutput', false);
end
