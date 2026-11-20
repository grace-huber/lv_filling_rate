projectFolder = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectFolder, 'ProvidedScripts'), fullfile(projectFolder, 'Scripts'));

if ~exist('datasetName', 'var') % a calling script may pick the dataset first
    datasetName = '002A';
end
datasetFile = fullfile(projectFolder, 'Datasets', [datasetName '.dcm']);

numberOfSections = 8;     % sections along the long axis (calculateLeftVentricleVolume)
sectionThicknessCm = 0.5; % each plane is traced on a 5 mm thick section
% Volume rate from this patient's DICOM header: Frame Time (0018,1063) is the time between volumes in ms.
% The anonymized datasets have a blank Frame Time; their rates come from the dataset list instead -> MANUAL ENTRY IF NOT INCLUDED
listedVolumesPerSecond = dictionary( ...
    ["p064_lp1a", "p064_lp2a", "p064_lp3a", "p065_lp1a", "p065_lp2a", "p065_lp3a"], ...
    [24,          32,          12,          28,          35,          13]);
previousWarnings = warning('off', 'all'); % anonymized headers trigger harmless dicominfo warnings
datasetHeader = dicominfo(datasetFile);
warning(previousWarnings);
if isfield(datasetHeader, 'FrameTime') && ~isempty(datasetHeader.FrameTime) && datasetHeader.FrameTime > 0
    volumesPerSecond = 1000 / double(datasetHeader.FrameTime);
elseif isKey(listedVolumesPerSecond, string(datasetName))
    volumesPerSecond = listedVolumesPerSecond(string(datasetName));
else
    error('setupWorkspace:noFrameTime', 'No Frame Time (0018,1063) in %s and no listed volume rate', datasetFile);
end
clear datasetHeader listedVolumesPerSecond previousWarnings
overlayFramesPerSecond = 2;

% Volumes to analyze (DICOM volume numbers start at 0). Datasets not listed use every volume.
listedVolumeRanges = dictionary("p064_lp1a", {0:27}); % one heart beat -> MANUAL ENTRY IF NOT INCLUDED
if isKey(listedVolumeRanges, string(datasetName))
    volumesToUse = listedVolumeRanges{string(datasetName)};
else
    volumesToUse = [];
end
clear listedVolumeRanges

outputFolder = fullfile(projectFolder, 'Results', datasetName);
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
resultsFile = fullfile(outputFolder, 'LeftVentricleVolumeResults.mat');
