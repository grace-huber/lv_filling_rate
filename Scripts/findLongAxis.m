function [apexPoint, axisDirection] = findLongAxis(frames, centerPoint, voxelSize)

apexSampleFrames = 5;

numberOfFrames = size(frames, 4);
[axisPoint, axisDirection] = fitCavityAxis(single(frames(:, :, :, 1)), centerPoint, voxelSize);

apexFrames = unique(round(linspace(1, numberOfFrames, apexSampleFrames)));
apexPoints = zeros(numel(apexFrames), 3);
for apexFrameIndex = 1:numel(apexFrames)
    apexPoints(apexFrameIndex, :) = findCavityTip(single(frames(:, :, :, apexFrames(apexFrameIndex))), ...
        axisPoint, axisDirection, voxelSize);
end
apexPoint = median(apexPoints, 1);

axisDirection = (axisPoint - apexPoint) / norm(axisPoint - apexPoint);
end

function apexPoint = findCavityTip(volume, axisPoint, axisDirection, voxelSize)
stepCm = 0.2;
minimumAreaSquareCm = 0.5;
maximumRadiusCm = 4;
maximumDistanceCm = 10;

[firstPerpendicular, secondPerpendicular] = perpendicularDirections(axisDirection);
halfSize = ceil(maximumRadiusCm / voxelSize);
step = stepCm / voxelSize;
levelCenter = axisPoint;
for stepIndex = 1:ceil(maximumDistanceCm / stepCm)
    [centroid, areaSquareCm] = cavityCentroid(volume, levelCenter - step * axisDirection, firstPerpendicular, ...
        secondPerpendicular, halfSize, voxelSize);
    if areaSquareCm < minimumAreaSquareCm
        break
    end
    levelCenter = centroid;
end
apexPoint = levelCenter - 0.5 * step * axisDirection;
end

function [axisPoint, axisDirection] = fitCavityAxis(volume, centerPoint, voxelSize)
numberOfIterations = 3;
fitHalfLengthCm = 3;
levelSpacingCm = 0.5;
maximumRadiusCm = 4;

levels = (-fitHalfLengthCm:levelSpacingCm:fitHalfLengthCm) / voxelSize;
halfSize = ceil(maximumRadiusCm / voxelSize);
axisPoint = centerPoint;
axisDirection = [0 0 1];
for iteration = 1:numberOfIterations
    [firstPerpendicular, secondPerpendicular] = perpendicularDirections(axisDirection);
    cavityCentroids = nan(numel(levels), 3);
    for levelIndex = 1:numel(levels)
        cavityCentroids(levelIndex, :) = cavityCentroid(volume, axisPoint + levels(levelIndex) * axisDirection, ...
            firstPerpendicular, secondPerpendicular, halfSize, voxelSize);
    end
    cavityCentroids = cavityCentroids(all(isfinite(cavityCentroids), 2), :);
    axisPoint = mean(cavityCentroids, 1);
    [~, ~, principalDirections] = svd(cavityCentroids - axisPoint, 'econ');
    axisDirection = principalDirections(:, 1)';
    if axisDirection(3) < 0
        axisDirection = -axisDirection; % apex toward the transducer (low depth)
    end
end
end

function [centroid, areaSquareCm] = cavityCentroid(volume, sliceCenter, firstPerpendicular, secondPerpendicular, ...
    halfSize, voxelSize)
shortAxisImage = extractObliqueSlice(volume, sliceCenter, firstPerpendicular, secondPerpendicular, halfSize);
contour = segmentCavity(shortAxisImage, halfSize + 1, halfSize, voxelSize, false);
cavityMask = poly2mask(contour(:, 1), contour(:, 2), size(shortAxisImage, 1), size(shortAxisImage, 2));
[cavityRows, cavityColumns] = find(cavityMask);
centroid = sliceCenter + (mean(cavityRows) - halfSize - 1) * firstPerpendicular ...
    + (mean(cavityColumns) - halfSize - 1) * secondPerpendicular;
areaSquareCm = nnz(cavityMask) * voxelSize^2;
end
