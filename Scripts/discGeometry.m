function geometry = discGeometry(apex, base, numberOfSections)

geometry.longAxisLength = norm(base - apex);
geometry.longAxisDirection = (base - apex) / geometry.longAxisLength;
[geometry.firstPerpendicular, geometry.secondPerpendicular] = perpendicularDirections(geometry.longAxisDirection);
geometry.axisCenter = (apex + base) / 2;
geometry.sectionThickness = geometry.longAxisLength / numberOfSections;
geometry.planeCenters = apex + (1:numberOfSections)' * geometry.sectionThickness * geometry.longAxisDirection;
geometry.halfSize = ceil(geometry.longAxisLength);
geometry.centerPixel = geometry.halfSize + 1;
geometry.planeRows = geometry.centerPixel - geometry.longAxisLength / 2 + (0:numberOfSections) * geometry.sectionThickness;
end
