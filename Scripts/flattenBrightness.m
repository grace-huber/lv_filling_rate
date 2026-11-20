function flattenedImage = flattenBrightness(shortAxisImage, centerPixel, maximumRadius)

[columnGrid, rowGrid] = meshgrid(1:size(shortAxisImage, 2), 1:size(shortAxisImage, 1));
fitRegion = hypot(columnGrid - centerPixel, rowGrid - centerPixel) <= maximumRadius & shortAxisImage > 0;
flattenedImage = shortAxisImage;
if nnz(fitRegion) <= 100
    return
end
slope = [ones(nnz(fitRegion), 1), columnGrid(fitRegion) - centerPixel, rowGrid(fitRegion) - centerPixel] ...
    \ log(max(double(shortAxisImage(fitRegion)), 1));
flattenedImage = shortAxisImage ./ exp(slope(2) * (columnGrid - centerPixel) + slope(3) * (rowGrid - centerPixel));
end
