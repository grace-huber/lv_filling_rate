function [volumeMilliliters, sections] = calculateLeftVentricleVolume(volume, apex, axisDirection, hingePoints, ...
    numberOfSections, voxelSize, sectionThicknessCm)

denseSpacingCm = 0.4;

[hingeNormal, hingeCenter] = fitHingePlane(hingePoints, axisDirection);
baseCm = dot(hingeCenter - apex, hingeNormal) / dot(axisDirection, hingeNormal) * voxelSize;
layoutBase = apex + (baseCm / voxelSize) * axisDirection;
tracedPlanes = 1:numberOfSections - 1;
planePositionsCm = (1:numberOfSections) * baseCm / numberOfSections;

denseCount = max(numberOfSections, ceil(baseCm / denseSpacingCm));
denseMasks = segmentShortAxisDiscs(volume, apex, layoutBase, denseCount, voxelSize, sectionThicknessCm);
densePositionsCm = (1:denseCount - 1) * baseCm / denseCount;

firstDiameterCm = perpendicularDistance(hingePoints(1, :), hingePoints(2, :), axisDirection) * voxelSize;
secondDiameterCm = perpendicularDistance(hingePoints(3, :), hingePoints(4, :), axisDirection) * voxelSize;
baseAreaSquareCm = pi * firstDiameterCm * secondDiameterCm / 4;

planeMasks = cell(1, numberOfSections);
planeMasks{numberOfSections} = false(size(denseMasks{1}));
planeAreasSquareCm = zeros(1, numberOfSections);
[planeMasks(tracedPlanes), planeAreasSquareCm(tracedPlanes)] = smoothWallProfiles(denseMasks(1:denseCount - 1), ...
    densePositionsCm, voxelSize, firstDiameterCm, secondDiameterCm, planePositionsCm(tracedPlanes));

positionsCm = [planePositionsCm(tracedPlanes), baseCm];
areasSquareCm = [planeAreasSquareCm(tracedPlanes), baseAreaSquareCm];
lowerAreas = areasSquareCm(1:end - 1);
upperAreas = areasSquareCm(2:end);
volumeMilliliters = planeAreasSquareCm(1) * planePositionsCm(1) / 2 ...
    + sum(diff(positionsCm) / 3 .* (lowerAreas + upperAreas + sqrt(lowerAreas .* upperAreas)));

sections = struct('layoutBase', layoutBase, 'baseCm', baseCm, 'planeMasks', {planeMasks}, ...
    'planeAreasSquareCm', planeAreasSquareCm, 'baseAreaSquareCm', baseAreaSquareCm, 'tracedPlanes', tracedPlanes);
end

function distance = perpendicularDistance(firstPoint, secondPoint, axisDirection)
difference = secondPoint - firstPoint;
distance = norm(difference - dot(difference, axisDirection) * axisDirection);
end

function [hingeNormal, hingeCenter] = fitHingePlane(hingePoints, axisDirection)
% Least squares plane through the 4 hinges; the normal points from the ventricle toward the atrium
[~, ~, principalDirections] = svd(hingePoints - mean(hingePoints, 1), 'econ');
hingeNormal = principalDirections(:, 3)';
if dot(hingeNormal, axisDirection) < 0
    hingeNormal = -hingeNormal;
end
hingeCenter = mean(hingePoints, 1);
end

function [smoothMasks, smoothAreasSquareCm] = smoothWallProfiles(planeMasks, planePositionsCm, voxelSize, ...
    firstDiameterCm, secondDiameterCm, outputPositionsCm)
numberOfAngles = 72;
outlierCm = 0.3;
outlierFraction = 0.2;
outlierPasses = 3;
profileWindowPlanes = 7;
aroundWindowAngles = 5;

imageSize = size(planeMasks{1}, 1);
centerPixel = (imageSize + 1) / 2;
angles = (0:numberOfAngles - 1) * 2 * pi / numberOfAngles;
rayDistances = (0:0.25:centerPixel - 1)';

numberOfPlanes = numel(planeMasks);
wallDistances = nan(numberOfPlanes, numberOfAngles);
for planeIndex = 1:numberOfPlanes
    for angleIndex = 1:numberOfAngles
        rayRows = round(centerPixel + rayDistances * cos(angles(angleIndex)));
        rayColumns = round(centerPixel + rayDistances * sin(angles(angleIndex)));
        onRay = planeMasks{planeIndex}(sub2ind([imageSize imageSize], rayRows, rayColumns));
        if any(onRay)
            wallDistances(planeIndex, angleIndex) = rayDistances(find(onRay, 1, 'last'));
        end
    end
end

samplePositionsCm = planePositionsCm(:);
outlierPixels = outlierCm / voxelSize;
windowPlanes = min(profileWindowPlanes, numberOfPlanes - mod(numberOfPlanes + 1, 2)); % odd, at most all planes
semiAxisRows = firstDiameterCm / 2 / voxelSize;
semiAxisColumns = secondDiameterCm / 2 / voxelSize;
baseDistances = semiAxisRows * semiAxisColumns ./ hypot(semiAxisColumns * cos(angles), semiAxisRows * sin(angles));
for angleIndex = 1:numberOfAngles
    profile = wallDistances(:, angleIndex);
    known = ~isnan(profile);
    profile(~known) = interp1(samplePositionsCm(known), profile(known), samplePositionsCm(~known));
    if numel(profile) >= 2
        profile(end) = min(profile(end), max(profile(end - 1), baseDistances(angleIndex)) + outlierPixels);
        profile(1) = min(profile(1), profile(2) + outlierPixels);
    end
    for pass = 1:outlierPasses
        expected = profile(1:end - 2) + (profile(3:end) - profile(1:end - 2)) .* (samplePositionsCm(2:end - 1) ...
            - samplePositionsCm(1:end - 2)) ./ (samplePositionsCm(3:end) - samplePositionsCm(1:end - 2));
        isOutlier = abs(profile(2:end - 1) - expected) > max(outlierPixels, outlierFraction * expected);
        if ~any(isOutlier)
            break
        end
        interior = profile(2:end - 1);
        interior(isOutlier) = expected(isOutlier);
        profile(2:end - 1) = interior;
    end
    if windowPlanes >= 3
        profile = smoothdata(profile, 'sgolay', windowPlanes, 'Degree', 2);
    end
    wallDistances(:, angleIndex) = max(profile, 0);
end

padding = aroundWindowAngles;
for planeIndex = 1:numberOfPlanes
    padded = wallDistances(planeIndex, [end - padding + 1:end, 1:end, 1:padding]);
    around = smoothdata(padded, 'gaussian', aroundWindowAngles);
    wallDistances(planeIndex, :) = around(padding + 1:end - padding);
end

outputDistances = interp1(planePositionsCm(:), wallDistances, outputPositionsCm(:), 'pchip');
smoothMasks = cell(1, numel(outputPositionsCm));
smoothAreasSquareCm = zeros(1, numel(outputPositionsCm));
for outputIndex = 1:numel(outputPositionsCm)
    distances = max(outputDistances(outputIndex, :), 0);
    smoothMasks{outputIndex} = poly2mask(centerPixel + distances .* sin(angles), centerPixel + distances .* cos(angles), ...
        imageSize, imageSize);
    smoothAreasSquareCm(outputIndex) = nnz(smoothMasks{outputIndex}) * voxelSize^2;
end
end
