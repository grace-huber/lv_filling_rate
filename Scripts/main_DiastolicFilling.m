close all
setupWorkspace

volumeTable = readtable(fullfile(outputFolder, 'LeftVentricleVolumes.csv'));

timeSeconds = (volumeTable.Frame - 1) / volumesPerSecond;
fprintf('Volume rate %.2f volumes/s (%.2f ms per volume)\n', volumesPerSecond, 1000 / volumesPerSecond);
metrics = discrete_filling_rate([timeSeconds, volumeTable.VolumeMilliliters], true);
set(gcf, 'Position', [100 100 900 900]);
exportgraphics(gcf, fullfile(outputFolder, 'DiastolicFillingDiscrete.png'));

fprintf('EDV %.1f mL, ESV %.1f mL, SV %.1f mL, EF %.1f%%\n', metrics.EDV, metrics.ESV, metrics.SV, metrics.EF);
fprintf('Peak filling rate %.1f mL/s, PFR/SV %.2f 1/s, time to peak %.3f s\n', ...
    metrics.PFR, metrics.PFR_SV, metrics.time_to_peak);

save(fullfile(outputFolder, 'DiastolicFillingDiscreteMetrics.mat'), 'metrics', 'volumesPerSecond');
