%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    
%           Function created by Bo-Jui Chang (bjo4), 2021/12/6 @ Dallas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [] = writetiffstack(image,path)

    [nx, ny, nz]= size(image);
    imgType= class(image);

    % Determine bits per sample based on data type
    switch imgType
        case {'uint8', 'int8'}
            bitsPerSample = 8;
        case {'uint16', 'int16'}
            bitsPerSample = 16;
        case {'uint32', 'int32', 'single'}
            bitsPerSample = 32;
        case {'uint64', 'int64', 'double'}
            bitsPerSample = 64;
        otherwise
            bitsPerSample = 16;
    end

    % Calculate estimated file size (bytes)
    % Each slice: nx * ny * (bitsPerSample/8), plus overhead for tags
    bytesPerPixel = bitsPerSample / 8;
    estimatedSize = nx * ny * nz * bytesPerPixel;

    % Use BigTIFF format if file size exceeds 4GB
    threshold = 4.0 * 1024^3; % 4.0 GB in bytes
    if estimatedSize > threshold
        tiffFile = Tiff(path, 'w8'); % 'w8' creates BigTIFF format
    else
        tiffFile = Tiff(path, 'w');  % Standard TIFF format
    end

    tagstruct.Photometric= Tiff.Photometric.MinIsBlack;
    tagstruct.ImageLength = nx;
    tagstruct.ImageWidth = ny;
    tagstruct.PlanarConfiguration= Tiff.PlanarConfiguration.Chunky;
    tagstruct.Compression = Tiff.Compression.None;
    tagstruct.BitsPerSample= bitsPerSample;

    % Set sample format based on data type
    if contains(imgType, 'int') && ~contains(imgType, 'uint')
        tagstruct.SampleFormat = Tiff.SampleFormat.Int;
    elseif contains(imgType, 'single') || contains(imgType, 'double')
        tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
    else
        tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
    end

    for iz=1:nz
        tiffFile.setTag(tagstruct);
        tiffFile.write(image(:,:,iz));
        if iz < nz
            tiffFile.writeDirectory();
        end
    end
    tiffFile.close();
end