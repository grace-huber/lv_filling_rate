function sectionImage = extractObliqueSection(volume, sectionCenter, rowDirection, columnDirection, halfSize, sectionThickness)

sectionNormal = cross(rowDirection, columnDirection);
numberOfPlanes = max(2, ceil(sectionThickness / 0.25) + 1);
planeOffsets = linspace(-0.5, 0.5, numberOfPlanes) * sectionThickness;

sectionImage = 0;
for planeOffset = planeOffsets
    sectionImage = sectionImage + extractObliqueSlice(volume, sectionCenter + planeOffset * sectionNormal, ...
        rowDirection, columnDirection, halfSize);
end
sectionImage = sectionImage / numberOfPlanes;
end
