clc; clear;

imagePath = '/archive/bioinformatics/Danuser_lab/Fiolka/MicroscopeDevelopment/omniOPM/Oil/U2OS/CLC/250417/Cell19/'
%imagePath = '/archive/bioinformatics/Danuser_lab/Fiolka/MicroscopeDevelopment/ClearedTissue/Data/Bo-Jui/20200326_ctASLM2_Hannah'
Cell_name= 'Top_Cell'; % e.g. Cell or Shear_Cell
Cell_index= [19]; % specify the cell index wish to be processed
%ch_number= 2; %specify channel numbers
ChannelstoProcess= [0]; % specify the channels wish to be processed, start from 0, i.e. CH00
timepoint= [0]; % specify the timepoint wish to be processed, leave it blank if you want to process all time points.

psfPath= '/archive/bioinformatics/Danuser_lab/Fiolka/MicroscopeDevelopment/SyntheticPSF/omniOPM/oil'; %/archive/bioinformatics/Danuser_lab/Fiolka/MicroscopeDevelopment/Lattice/simulatedPSFnOTF
psf {1}= 'NA0.2_ill_488_det_520_NA1_40degree_0.118umxyz_BottomtoTop.tif'; % Shear30_1_PSF_NA1.1_ExpMyHexLattice_Sp1.2502_NA0.50,0.40_SAobjective_xy104nm_z300nm_xyview.tif
%psfPath= '/archive/bioinformatics/Danuser_lab/Fiolka/MicroscopeDevelopment/ClearedTissue/Data/Bo-Jui/20200326_ctASLM2_Hannah';
%psf {1}= 'NA0.2_ill_405_det_461_NA1_0.15umxyz_2.tif';
%psf {1}= 'NA0.2_ill_488_det_520_NA1_0.15umxyz_2.tif';
%psf {1}= 'NA0.2_ill_587_det_610_NA1_0.15umxyz_2.tif';
%psf {1}= 'NA0.2_ill_640_det_680_NA1_0.15umxyz_2.tif'; %NA0.2_ill_488_det_520_NA1_0.15umxyz_2
%psf {1}= 'NA0.16_ill_561_det_610_NA1_0.118umxyz.tif';
%psf {3}= 'ill_488_NA0.2_ill_640_det_680_NA1_0.15umxyz.tif';
%psf {4}= 'Sheared_45_1_PSF_lightsheet_ill488_det510_160xy_283z.tif';
%psf {3}= 'Sheared_45_1_PSF_lightsheet_ill488_det510_160xy_283z.tif';
%psf {4}= 'Sheared_45_1_PSF_lightsheet_ill488_det510_160xy_283z.tif';

background= 0; % measure the background in the PSF data 

iter=10; %number of iterations
dir_Dec=fullfile(imagePath,strcat('DBv8_synPSFOPM_',num2str(iter),'_chop',num2str(background)));
% dir_Dec=fullfile(imagePath,strcat('DBv5_unsheared_PSFExpMyHexLattice_Sp1.2502_iter',num2str(iter),'_chop',num2str(background)));
mkdir(dir_Dec);


%% load PSF
for p=1: size(psf,2)
    filepath=fullfile(psfPath,psf{p});
    PSFimage=readtiffstack(filepath);
  
PSFimage=double(PSFimage);
PSFimage=PSFimage-background;
PSFimage=abs(PSFimage);
%PSFimage=PSFimage./sum(sum(sum(PSFimage)));
PSF{p}=PSFimage;

end
clear PSFimage

%% Deconvolution
%names1 = dir(fullfile(imagePath,'Cell*'));
%names1 = dir(fullfile(imagePath,'Shear_Cell*_45'));
     
%if size(Cell_index)==0
%    numfolder=size(names1,1);
%else
%    numfolder=size(Cell_index,2);
%end

numfolder=size(Cell_index,2);
ch_number= size(ChannelstoProcess,2);

for c=1:numfolder
    
    names2=strcat(Cell_name,num2str(Cell_index(c)));
    
    numImages=size(dir(fullfile(imagePath,names2)),1)-3; % if Cell_name= 'Cell*',   numImages=size(dir(fullfile(imagePath,names2)),1)-3
    if size(timepoint,2)==0
        t_st=0;
        %t_end=(size(names2,1)-2)/ch_number;
        t_end=round(numImages/ch_number)-1;
    else
        t_st=min(timepoint);
        t_end=max(timepoint);
    end
    
    for t=t_st:t_end
    
        for ch=1:ch_number
        
        tic
       
       filename=strcat('1_CH',num2str(ChannelstoProcess(ch),'%02.0f'),'_',num2str((t),'%06.0f'),'.tif');
       %filename=strcat('1_CH',num2str((ch-1),'%02.0f'),'_',num2str((t-1),'%06.0f'),'.tif');
       filepath=fullfile(imagePath,names2,filename);
%       InfoImage=imfinfo(filepath);
%       mImage=InfoImage(1).Height;
%       nImage=InfoImage(1).Width;
%       NumberImages=length(InfoImage);
%       %NumberImages=958;
%       
%       FinalImage=zeros(mImage,nImage,NumberImages,'uint16');
%
%       TifLink = Tiff(filepath, 'r');
%for i=1:NumberImages
%   TifLink.setDirectory(i);
%   FinalImage(:,:,i)=TifLink.read();
%end
%TifLink.close();

FinalImage= readtiffstack(filepath);
mImage= size(FinalImage,1);
nImage= size(FinalImage,2);
NumberImages= size(FinalImage,3);
%% Deconvolution
%padx=ceil(mImage/2);
%pady=ceil(nImage/2);
%padz=ceil(NumberImages/2);
%E1=padarray(single(FinalImage),[20 20],'symmetric') ; 
E1=padarray(single(FinalImage),[20 20 20],'symmetric') ; 
maxE1=max(E1(:));
minE1=min(E1(:));
psfi=single(PSF{ch});
%psfi=psfi./max(psfi(:));
[Dec,psfr]=deconvblind(E1,psfi,iter);
%Dec=Dec(21:20+mImage,21:20+nImage);
Dec=Dec(21:20+mImage,21:20+nImage,21:20+NumberImages);
Dec=(Dec-min(Dec(:)))/(max(Dec(:)-min(Dec(:))));
Dec=Dec.*(maxE1-minE1)+minE1;
%Dec=Dec./max(Dec(:));
Dec=uint16(Dec);

%% save deconvolved image
%finalPath=fullfile(dir_Dec,strcat('FirstBlind_',names2));
%mkdir(finalPath);

%Decname=fullfile(finalPath,strcat('Dec_',filename));
%Decname=fullfile(finalPath,filename);
    
%    [nx, ny, nz]= size(Dec);
%    imgType= class(Dec);
%    tagstruct.Photometric= Tiff.Photometric.MinIsBlack;
%    tagstruct.ImageLength = nx;
%    tagstruct.ImageWidth = ny;
%    tagstruct.PlanarConfiguration= Tiff.PlanarConfiguration.Chunky;
%    tagstruct.Compression = Tiff.Compression.None;
%    tagstruct.BitsPerSample= 16;
    
%    tiffFile=Tiff(Decname, 'w');
    
%    for iz=1:nz
%        tiffFile.setTag(tagstruct);
%        tiffFile.write(Dec(:,:,iz));
%        tiffFile.writeDirectory();
        
%    end
%    tiffFile.close();
    
%% save retrived psf 
psfr=psfr./max(psfr(:));
psfr2=uint16(60000*psfr);

PSFfolder=fullfile(dir_Dec,strcat('PSFr_',names2));
mkdir(PSFfolder);
PSFname=fullfile(PSFfolder,strcat(names2,'psfr',num2str(ch),'.tif'));

writetiffstack(psfr2, PSFname);
    
%    [nx, ny, nz]= size(psfr2);
%    imgType= class(psfr2);
%    tagstruct.Photometric= Tiff.Photometric.MinIsBlack;
%    tagstruct.ImageLength = nx;
%    tagstruct.ImageWidth = ny;
%    tagstruct.PlanarConfiguration= Tiff.PlanarConfiguration.Chunky;
%    tagstruct.Compression = Tiff.Compression.None;
%    tagstruct.BitsPerSample= 16;
    
%    tiffFile=Tiff(PSFname, 'w');
    
%    for iz=1:nz
%        tiffFile.setTag(tagstruct);
%        tiffFile.write(psfr2(:,:,iz));
%        tiffFile.writeDirectory();
        
%    end
%    tiffFile.close();


%% DoubleBlindDeconvolution
%[Dec2]=deconvwnr(E1,psfr,100);
[Dec2]=deconvlucy(E1,psfr,iter);
%[Dec2]=deconvreg(E1,psfr);
%[Dec2,psfr3]=deconvblind(E1,psfr,iter);
%Dec2=Dec2(21:20+mImage,21:20+nImage);
Dec2=Dec2(21:20+mImage,21:20+nImage,21:20+NumberImages);
Dec2=(Dec2-min(Dec2(:)))/(max(Dec2(:)-min(Dec2(:))));
Dec2=Dec2.*(maxE1-minE1)+minE1;
%Dec=Dec./max(Dec(:));
Dec2=uint16(Dec2);
%Dec2=Dec2./max(Dec2(:));
%Dec2=uint16(Dec2*maxE1);

%% save DoubleBlindDeconvolved image
%finalPath2=fullfile(dir_Dec,strcat('Tikhonov_',names2));
%finalPath2=fullfile(dir_Dec,strcat('Wiener0.1_',names2));
finalPath2=fullfile(dir_Dec,strcat('DB2_',names2));
mkdir(finalPath2);
Decname2=fullfile(finalPath2,filename);
    
       writetiffstack(Dec2,Decname2);
    %writeBigtiffstack(Dec2,Decname2);
%% save retrived psf 
%psfr3=psfr3./max(psfr3(:));
%psfr4=uint16(60000*psfr3);

%PSFname2=fullfile(dir_Dec,strcat(names2,'DBpsfr',num2str(c),'.tif'));
    
%    [nx, ny, nz]= size(psfr4);
%    imgType= class(psfr4);
%    tagstruct.Photometric= Tiff.Photometric.MinIsBlack;
%    tagstruct.ImageLength = nx;
%    tagstruct.ImageWidth = ny;
%    tagstruct.PlanarConfiguration= Tiff.PlanarConfiguration.Chunky;
%    tagstruct.Compression = Tiff.Compression.None;
%    tagstruct.BitsPerSample= 16;
   
%    tiffFile=Tiff(PSFname2, 'w');
    
%    for iz=1:nz
%        tiffFile.setTag(tagstruct);
%        tiffFile.write(psfr4(:,:,iz));
%        tiffFile.writeDirectory();
%        
%    end
%    tiffFile.close();
         
    
toc, disp('Done')
        end
    end
end

disp('All Done')