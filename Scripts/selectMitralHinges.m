function hingePoints = selectMitralHinges(volume, apexPoint, axisDirection, voxelSize, titlePrefix)

if nargin < 5
    titlePrefix = '';
end
viewHalfSizeCm = 7;
apexToViewCenterCm = 5.5;

halfSize = ceil(viewHalfSizeCm / voxelSize);
viewCenter = apexPoint + (apexToViewCenterCm / voxelSize) * axisDirection;
[firstPerpendicular, secondPerpendicular] = perpendicularDirections(axisDirection);
viewDirections = [firstPerpendicular; secondPerpendicular];
apexRow = halfSize + 1 - apexToViewCenterCm / voxelSize;

hingePoints = zeros(4, 3);
for viewIndex = 1:2
    longAxisImage = extractObliqueSlice(volume, viewCenter, axisDirection, viewDirections(viewIndex, :), halfSize);

    figure(1); clf
    set(gcf, 'WindowState', 'maximized', 'Color', 'k');
    drawnow
    imshow(longAxisImage, [], 'InitialMagnification', 'fit');
    set(gca, 'Units', 'normalized', 'Position', [0.01 0.01 0.98 0.93]);
    hold on
    plot(halfSize + 1, apexRow, 'g+', 'MarkerSize', 16, 'LineWidth', 2);
    plot([halfSize + 1 halfSize + 1], [apexRow size(longAxisImage, 1)], 'g:', 'LineWidth', 1.5);
    title(sprintf(['%s  View %d of 2: click the two mitral hinge points ' ...
        '(where each leaflet meets the wall)'], titlePrefix, viewIndex), 'FontSize', 16, 'Color', 'w');

    for hingeIndex = 1:2
        [clickColumn, clickRow] = ginput_userdefinedcolour(1, [223 0 255] / 255);   % #DF00FF
        plot(clickColumn, clickRow, 'mo', 'MarkerSize', 12, 'LineWidth', 2);
        drawnow
        hingePoints(2 * (viewIndex - 1) + hingeIndex, :) = viewCenter + (clickRow - halfSize - 1) * axisDirection ...
            + (clickColumn - halfSize - 1) * viewDirections(viewIndex, :);
    end
    pause(0.3)
    close(1)
end
end
