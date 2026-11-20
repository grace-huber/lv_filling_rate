function centerPoint = selectLeftVentricleCenter(volume)

middleDepth = round(size(volume, 3) / 2);

figure(1); clf
set(gcf, 'WindowState', 'maximized', 'Color', 'k');
drawnow
imshow(squeeze(volume(:, :, middleDepth))', [], 'InitialMagnification', 'fit');
set(gca, 'Units', 'normalized', 'Position', [0.01 0.01 0.98 0.93]);
title('Click the center of the left ventricle', 'FontSize', 16, 'Color', 'w');
[centerWidth, centerHeight] = ginput_userdefinedcolour(1, [223 0 255] / 255);   % #DF00FF
close(1)

centerPoint = [centerWidth, centerHeight, middleDepth];
end
