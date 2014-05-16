javaaddpath('MyJavaCodes.jar'); 
import HelperPackage.*; % This is to use the lcas based similarity I wrote in java
%import HelperPackage.Helper; % This is to use the lcas based similarity I wrote in java

s=LCS.getSimilarity('hello', 'hello');

%%mention the input directory
inputDir='../data_vanc-1k';


%% Input and output files are described below
locationsFile = strcat(inputDir,'/','data.images'); % Input. Patrick supplied this. Locations against images are provides
tagsFile = strcat(inputDir,'/','data.tags'); % Input. Patrick supplied this. tag against images are provided

filteredTagsFile=strcat(inputDir,'/','dumpFiltered.tag'); %Output. Similar to Patrick's dump.tag file, but contains filtered tags

IDvsImageFile = strcat(inputDir,'/','IDvsImage.map'); %output. 
IDvsTagFile=strcat(inputDir,'/','IDvsTag.map'); %output
IDvsLocationFile=strcat(inputDir,'/','IDvsLocation.map'); %output

ImageTagsFile=strcat(inputDir,'/','ImageTagsFile.txt'); %output. Contains only IDs
ImageLocationsFile=strcat(inputDir,'/','ImageLocationsFile.txt'); %Output. Contains only IDs

Helper.filterImageTagsBasedOnAThreshold(tagsFile, filteredTagsFile, 0); % Filter the tags file and produce a new one
tagsFile=filteredTagsFile; % work with the filtered file

Helper.produceIDFileForTwoColumnsOfTwoFiles(locationsFile, 1,...
    tagsFile, 1, IDvsImageFile);
Helper.produceIDFileForASpecificColumn(tagsFile, 2, IDvsTagFile);
Helper.produceIDFileForTwoMergedColumns(...
            locationsFile, IDvsLocationFile, 4, 5); % ID based in lattitude and longitude.

Helper.replaceImageNamesAndTagsWithIdsOfTheTagsFile(tagsFile, ...
    ImageTagsFile, IDvsImageFile, IDvsTagFile);
Helper.replaceImageNamesWithIdsOfTheLocaionFile(locationsFile,...
                ImageLocationsFile, IDvsImageFile, IDvsLocationFile);
% Helper.replaceImageNamesWithIdsOfTheLocaionFile(locationsFile,...
%                 ImageLocationsFile, IDvsImageFile);
