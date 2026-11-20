function sliceImage = extractObliqueSlice(volume, sliceCenter, rowDirection, columnDirection, halfSize)

[columnOffsets, rowOffsets] = meshgrid(-halfSize:halfSize);
widthIndices = sliceCenter(1) + rowOffsets * rowDirection(1) + columnOffsets * columnDirection(1);
heightIndices = sliceCenter(2) + rowOffsets * rowDirection(2) + columnOffsets * columnDirection(2);
depthIndices = sliceCenter(3) + rowOffsets * rowDirection(3) + columnOffsets * columnDirection(3);

% interp3 takes coordinates as (column, row, page) = (height, width, depth)
sliceImage = interp3(volume, heightIndices, widthIndices, depthIndices, 'linear', 0);
end
