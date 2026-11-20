function [x] = dicomGE(filename)
% loads a GE VolDICOM file.

%filename = "D:\bme 543\datasets\O4NC9180";


fid=fopen(filename,'r','l');    % Note small L "l" for Little Endian
if(~fid) error('could not open input file'); end;

% Waste first 128 Bytes
WasteBytes  = fread(fid,128,'char');

% Waste Dicom Label
DICM    = char(fread(fid,4,'char'));

% Initialize Dicom Tags for "while" loop
TagA = 0;
TagB = 0;
N2 = 0;

% The data is stored in the sequence with the following tags:
DataTagA = hex2dec('7fe0');
DataTagB = hex2dec('10');

LoopCounter = 0; % 
dataLoopCounter = 0;

x.filetype = 'GE VolDICOM';

% TagA == x24
%x.CineRate = 0;
x.EffectiveDuration = 0;
x.FrameTime = 0;
%x.FrameDelay = 0;
x.HeartRate = 0;
x.ActualFrameDuration = 0;
%x.RWaveTimeVector = 0;

% TagA == x40
x.NumVolumes = 0;   %compliant
x.width = 0;        %compliant
x.height = 0;       %compliant
x.depth = 0;        %compliant
x.widthspan = 0;    %compliant
x.heightspan = 0;   %compliant
x.depthspan = 0;    %compliant

x.LoadedVolCount = 0;
x.data = [];


while ( ~feof(fid) && LoopCounter < 200)
    LoopCounter = LoopCounter+1;
    loc = ftell(fid);

    field.TagA = fread(fid,1,'ushort');
    field.TagB = fread(fid,1,'ushort');
    field.CODE = char(fread(fid,2,'char'))';
    field.N = fread(fid,1,'ushort');
    
    x = ParseTags(fid,field,x);
    
end


%% Reshape and see what we got
x.NumVolumes = x.LoadedVolCount;
x.data = reshape(x.data, [x.VolumeGridSize(1) x.VolumeGridSize(2) x.VolumeGridSize(3) x.LoadedVolCount]);

newSR = max(x.VoxelSize);
scale = x.VoxelSize / newSR;
newSize = x.VolumeGridSize .* scale;

for i = 1:x.LoadedVolCount
    tmp = squeeze(x.data(:,:,:,i));
    NewVols(:,:,:,i) = imresize3(tmp,newSize);  %'Scale',scale);
end

sz = size(NewVols);

x.width = sz(1);
x.height = sz(2); 
x.depth = sz(3);

pdim = x.VolumeGridSize .* newSR .* 100; 
x.widthspan = pdim(1);
x.heightspan = pdim(2);
x.depthspan = pdim(3);
