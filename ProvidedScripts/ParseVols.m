function [x] = ParseVols(fid,field,x)
%PARSEVOLS Summary of this function goes here
%   Detailed explanation goes here

% check to make sure we haven't hit EOF
if (max(size(field.TagA) > 0))

%We know we're in the final sequence, we need to pull out volumes. 

%skip GE stamp
TagA = fread(fid,1,'ushort');
TagB = fread(fid,1,'ushort');
CODE = char(fread(fid,2,'char')');
N = fread(fid,1,'ushort');

value = fread(fid,N,'char');

%skip timestamp
TagA = fread(fid,1,'ushort');
TagB = fread(fid,1,'ushort');
CODE = char(fread(fid,2,'char')');
N = fread(fid,1,'ushort');

value = fread(fid,N,'char');

%skip size?
TagA = fread(fid,1,'ushort');
TagB = fread(fid,1,'ushort');
CODE = char(fread(fid,2,'char')');
N = fread(fid,1,'ushort');

value = fread(fid,N,'uint8');

%volume data?
TagA = fread(fid,1,'ushort');
TagB = fread(fid,1,'ushort');
CODE = char(fread(fid,2,'char')');
N = fread(fid,1,'ushort');

% N = 0 as this is OB. 
%value = fread(fid,N,'uint8');
lilN = fread(fid,1,'ulong');

value = fread(fid,lilN,'uint8');
x.data = [x.data value];
x.LoadedVolCount = x.LoadedVolCount + 1;

lf.TagA = fread(fid,1,'ushort');
lf.TagB = fread(fid,1,'ushort');
lf.CODE = 'xx';
lf.N = fread(fid,1,'ulong');

x = ParseVols(fid,lf,x);

end
end

