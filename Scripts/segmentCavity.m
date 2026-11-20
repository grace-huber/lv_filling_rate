function contour = segmentCavity(shortAxisImage, centerPixel, maximumRadius, voxelSize, includePapillaryMuscles)

smoothingSigmaCm = 0.15;
bloodSampleRadiusCm = 0.5;
edgePersistenceCm = 0.15;
localWallCm = 1;
compactWallFraction = 0.5;
minimumWallContrast = 0.4;
angularMedianDegrees = 20;
ellipseOutlierFraction = 0.2;
outwardTolerance = 0.1;
if includePapillaryMuscles
    edgeFraction = 0.35;
    inwardTolerance = 0; % fill any remaining papillary dips out to the wall
else
    edgeFraction = 0.5;
    inwardTolerance = 0.1;
end
angleStepDegrees = 2;
radiusStep = 0.5;

smoothedImage = imgaussfilt(shortAxisImage, smoothingSigmaCm / voxelSize);

[columnGrid, rowGrid] = meshgrid(1:size(shortAxisImage, 2), 1:size(shortAxisImage, 1));
distanceFromAxis = hypot(columnGrid - centerPixel, rowGrid - centerPixel);
searchRegion = distanceFromAxis <= maximumRadius & shortAxisImage > 0;
bloodLevel = median(smoothedImage(distanceFromAxis <= bloodSampleRadiusCm / voxelSize));
otsuThreshold = multithresh(smoothedImage(searchRegion));
tissueLevel = mean(smoothedImage(searchRegion & smoothedImage > otsuThreshold));

angles = deg2rad(0:angleStepDegrees:360 - angleStepDegrees);
radii = (0:radiusStep:maximumRadius)';
rayColumns = centerPixel + radii * cos(angles);
rayRows = centerPixel + radii * sin(angles);
rayIntensities = interp2(smoothedImage, rayColumns, rayRows, 'linear', 0);
rayInFieldOfView = interp2(shortAxisImage, rayColumns, rayRows, 'nearest', 0) > 0;

rayPeaks = max(rayIntensities .* rayInFieldOfView, [], 1);
edgeThreshold = bloodLevel + edgeFraction * (min(rayPeaks, tissueLevel) - bloodLevel);
isWall = movmin(rayIntensities > edgeThreshold, [0 round(edgePersistenceCm / voxelSize / radiusStep)], 1) | ~rayInFieldOfView;
isWall(end, :) = true;
[~, borderIndices] = max(isWall, [], 1);
if includePapillaryMuscles
    localWallSamples = round(localWallCm / voxelSize / radiusStep);
    for angleIndex = 1:numel(angles)
        searchRange = borderIndices(angleIndex):min(borderIndices(angleIndex) + localWallSamples, numel(radii));
        searchIntensities = rayIntensities(searchRange, angleIndex);
        localPeak = max(searchIntensities);
        wallThreshold = min(bloodLevel + compactWallFraction * (localPeak - bloodLevel), localPeak);
        borderIndices(angleIndex) = searchRange(find(searchIntensities >= wallThreshold, 1, 'first'));
    end
end
borderRadii = radii(borderIndices)';

stoppedOnTissue = rayInFieldOfView(sub2ind(size(isWall), borderIndices, 1:numel(angles))) & borderIndices < numel(radii);
isReliable = stoppedOnTissue & (rayPeaks - bloodLevel) >= minimumWallContrast * (tissueLevel - bloodLevel);
if nnz(isReliable) >= 0.1 * numel(angles)
    if includePapillaryMuscles
        wallColumns = borderRadii .* cos(angles);
        wallRows = borderRadii .* sin(angles);
        pointRadii = hypot(wallColumns - median(wallColumns(isReliable)), wallRows - median(wallRows(isReliable)));
        outlierBounds = [1 / 1.75, 1.75];
    else
        pointRadii = borderRadii; % distances from the axis (exact, so radii on a bound are treated as before)
        outlierBounds = [0.5, 1.5];
    end
    typicalRadius = median(pointRadii(isReliable));
    isReliable = isReliable & pointRadii >= outlierBounds(1) * typicalRadius & pointRadii <= outlierBounds(2) * typicalRadius;
end
if nnz(isReliable) >= 0.1 * numel(angles)
    reliableAngles = angles(isReliable);
    reliableRadii = borderRadii(isReliable);
    borderRadii = interp1([reliableAngles - 2 * pi, reliableAngles, reliableAngles + 2 * pi], ...
        repmat(reliableRadii, 1, 3), angles, 'linear');
else
    isReliable = true(size(angles));
end

medianWindow = round(angularMedianDegrees / angleStepDegrees);
paddedRadii = [borderRadii(end - medianWindow + 1:end), borderRadii, borderRadii(1:medianWindow)];
paddedRadii = movmean(movmedian(paddedRadii, medianWindow), 5);
borderRadii = paddedRadii(medianWindow + 1:end - medianWindow);

fitAngles = angles(isReliable);
fitRadii = borderRadii(isReliable);
for fitPass = 1:2
    ellipseRadii = fitEllipseRadii(fitAngles, fitRadii, angles);
    fitResiduals = abs(fitRadii - ellipseRadii(isReliable)) ./ ellipseRadii(isReliable);
    keepPoints = fitResiduals <= ellipseOutlierFraction;
    if nnz(keepPoints) >= 6
        fitAngles = fitAngles(keepPoints);
        fitRadii = fitRadii(keepPoints);
        isReliable(isReliable) = keepPoints;
    end
end
ellipseRadii = fitEllipseRadii(fitAngles, fitRadii, angles);
borderRadii = min(max(borderRadii, (1 - inwardTolerance) * ellipseRadii), (1 + outwardTolerance) * ellipseRadii);

contour = [centerPixel + borderRadii' .* cos(angles'), centerPixel + borderRadii' .* sin(angles')];
end

function ellipseRadii = fitEllipseRadii(fitAngles, fitRadii, angles)
ellipseRadii = median(fitRadii) * ones(size(angles));
if nnz(fitRadii > 0) < 6
    return
end
x = fitRadii(:) .* cos(fitAngles(:));
y = fitRadii(:) .* sin(fitAngles(:));
conic = [x.^2, x .* y, y.^2, x, y] \ ones(numel(x), 1);
cosines = cos(angles);
sines = sin(angles);
quadraticTerm = conic(1) * cosines.^2 + conic(2) * cosines .* sines + conic(3) * sines.^2;
linearTerm = conic(4) * cosines + conic(5) * sines;
isEllipse = 4 * conic(1) * conic(3) - conic(2)^2 > 0 && all(quadraticTerm > 0);
if isEllipse
    ellipseRadii = (-linearTerm + sqrt(linearTerm.^2 + 4 * quadraticTerm)) ./ (2 * quadraticTerm);
end
end
