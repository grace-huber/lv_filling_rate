function [x] = ParseTags(fid,field,x)
%PARSETAGS Parse the dicom tags from the file
%   fid = input file
%   field = the tags, code and size from the last read header
%   x = the dcm struct containing all the info.

% First let's check if it's important info.
%display([num2str(dec2hex(field.TagA)) ' ' num2str(dec2hex(field.TagB)) ' ' field.CODE ' ' num2str(field.N) ' ' num2str(ftell(fid))])

if max(size(field.TagA)) > 0
    
    switch field.TagA
        case hex2dec('18') % data fields
            switch field.TagB
                case hex2dec('1063')
                    temp = char(fread(fid,field.N,'char'))';
                    x.FrameTime = str2double(temp);
                case hex2dec('1066')
                    temp = char(fread(fid,field.N,'char'))';
                    x.FrameDelay = str2double(temp);
                case hex2dec('1088')
                    temp = char(fread(fid,field.N,'char')');
                    x.HeartRate = str2double(temp);
                case hex2dec('1242')    
                    temp = char(fread(fid,field.N,'char'))';
                    x.ActualFrameDuration = str2double(temp);  
                otherwise
                    if (all(field.CODE == 'OB') || all(field.CODE == 'SQ'))
                        subsize = fread(fid,1,'ulong');
                        WasteBytes = fread(fid,subsize,'char');
                    else
                        WasteBytes = fread(fid,field.N,'char');
                    end
            end
        case hex2dec('28') % data fields
            switch field.TagB
                case hex2dec('8')
                    temp = fread (fid,2,'char')';
                    x.NumVolumes = str2double(char(temp));
                otherwise
                    if (all(field.CODE == 'OB') || all(field.CODE == 'SQ'))
                        subsize = fread(fid,1,'ulong');
                        WasteBytes = fread(fid,subsize,'char');
                    else
                        WasteBytes = fread(fid,field.N,'char');
                    end
            end
        case hex2dec('7fe0') % this contains pixel data
            switch field.TagB
                case hex2dec('10') % pixel data, type should be OB.
                    bigN = fread(fid,1,'ulong'); % now should be aligned to the first tag in the sequence?
                    lf.TagA = fread(fid,1,'ushort');
                    lf.TagB = fread(fid,1,'ushort');
                    lf.CODE = 'xx';
                    lf.N = fread(fid,1,'ulong');
                    
                    x = ParseTags(fid,lf,x);
                otherwise
                    if (all(field.CODE == 'OB') || all(field.CODE == 'SQ'))
                        subsize = fread(fid,1,'ulong');
                        WasteBytes = fread(fid,subsize,'char');
                    else
                        WasteBytes = fread(fid,field.N,'char');
                    end
            end
        case hex2dec('7fe1') % this contains GE volume infos
            switch field.TagB
                case hex2dec('10')
                    case hex2dec('20')
                        x.GEMS = char(fread(fid,field.N,'char'))';
    
                    case hex2dec('2001')
                        x.FileVersion = char(fread(fid,field.N,'char'))';
                    
                    case hex2dec('2003')
                        x.VolumeGridSize = fread(fid,3,'long');
                    case hex2dec('2004')
                        x.VoxelSize = fread(fid,3,'double');
                    case hex2dec('2005')
                        x.ProbePosition = fread(fid,6,'double');
                    case hex2dec('2006')
                        x.AverageCycleLength = fread(fid,1,'double');
                    case hex2dec('2007')
                        x.FirstFrameDelay = fread(fid,1,'double');
                    case hex2dec('2008')
                        x.CompressionAlgorithm = char(fread(fid,field.N,'char'))';
                    case hex2dec('2009')
                        ssN = fread(fid,1,'ulong');
                        value = fread(fid,ssN,'char');
                    case hex2dec('200A')
                        x.CompressionQuality = fread(fid,1,'double');
                    case hex2dec('200B')
                        x.ECGStartTime = fread(fid,1,'double');
                    case hex2dec('200C')
                        x.ECGTimeIncrement = fread(fid,1,'double');
                    case hex2dec('200D')
                        value = fread(fid,field.N,'char');
                    case hex2dec('2050')
                        bigN = fread(fid,1,'ulong'); % now should be aligned to the first tag in the sequence?
                        lf.TagA = fread(fid,1,'ushort');
                        lf.TagB = fread(fid,1,'ushort');
                        lf.CODE = 'xx';% char(fread(fid,2,'char')');
                        lf.N = fread(fid,1,'ulong');
                        x = ParseVols(fid,lf,x);
                    case hex2dec('2051')
                        value = fread(fid,1,'double');
                    case hex2dec('2052')
                        value = fread(fid,1,'float');
                    case hex2dec('2053')
                        ssN = fread(fid,1,'ulong');
                        x.data = [x.data fread(fid,ssN,'uint8')];
                        x.LoadedVolCount = x.LoadedVolCount +1;
                otherwise
                    if (all(field.CODE == 'OB') || all(field.CODE == 'SQ'))
                        subsize = fread(fid,1,'ulong');
                        WasteBytes = fread(fid,subsize,'char');
                    else
                        WasteBytes = fread(fid,field.N,'char');
                    end
            end
        case hex2dec('FFFE') % this is a reservered tag for sequence delimiters
            switch field.TagB
                case hex2dec('E000') % Item flag. read tags and parse
                    %bigN = fread(fid,1,'ulong');
                    value = fread(fid,field.N,'char');
                    
                    lf.TagA = fread(fid,1,'ushort');
                    lf.TagB = fread(fid,1,'ushort');
                    lf.CODE = 'xx'; %char(fread(fid,2,'char')');
                    lf.N = fread(fid,1,'ulong');
                    x = ParseTags(fid,lf,x);
                case hex2dec('E0DD') % sequence delimiter. read the reserved DWORD and carry on
                    %bigN = fread(fid,1,'ulong');
                    % already read the reserved DWORD above. should just carry
                    % on....
                    dummy = 1;
                otherwise % I don't think we encounter any other tags in here, but just to be safe....
                    if (all(field.CODE == 'OB') || all(field.CODE == 'SQ'))
                        subsize = fread(fid,1,'ulong');
                        WasteBytes = fread(fid,subsize,'char');
                    else
                        WasteBytes = fread(fid,field.N,'char');
                    end
            end
    
        otherwise % this is not something we need at the moment.
            if (all(field.CODE == 'OB') || all(field.CODE == 'SQ'))
                subsize = fread(fid,1,'ulong');
                WasteBytes = fread(fid,subsize,'char');
            else
                WasteBytes = fread(fid,field.N,'char');
            end
    end

end
end

