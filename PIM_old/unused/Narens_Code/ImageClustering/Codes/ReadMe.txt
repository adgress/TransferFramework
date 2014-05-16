1. Run constructFiles
    This will take two files as inputs and generate four other files.
    The input files are as follows:
    -------------------------------    
    locationsFile = '../data/dump.imgs'; % Input. Patrick supplied this. Locations against images are provides
    The columns are described as follows.
    ImageName	User	timeTaken	lattitude	longitude	accuracyLevel

    tagsFile = '../data/dump.tag'; % Input. Patrick supplied this. tag against images are provided
    The columns are described as follows.
    ImageName	Tag
    
    The output files are as follows:
    ---------------------------------
    filteredTagsFile=strcat(inputDir,'/','dumpFiltered.tag'); %Output. 
    Similar to Patrick's dump.tag file, but contains filtered tags

    IDvsImageFile = '../data/IDvsImage.map'; %output. 
    This provides ID for each image filenames found in the two files Patrick supplied.
    The IDs start from 1 and ends at total number of images.
    The file is actually a map between ID and image filename.
    The columns are described as follows.
    ImageID  ImageName

    IDvsTagFile='../data/IDvsTag.map'; %output
    This provides ID for each tag found in tagsFile Patrick supplied.
    The IDs start from 1 and ends at total number of tags.
    The file is actually a map between ID and tag.
    The columns are described as follows.    
    TagID  Tag

    IDvsLocationFile='../data/IDvsLocation.map'; %output
    This provides ID for each location. Location is composed of lattitute 
    and longitude.
    The columns are described as follows:
    LocationID  Lattitude   Longitude

    ImageTagsFile='../data/ImageTagsFile.txt'; %output. Contains only IDs
    This file has same entries as the tagsFile Patrick supplied.
    The only difference is, the entries of ImageName and Tag columns are 
    replaced by corresponding IDs of the image names and Tags.
    The total number of entries in tagsFile and ImageTagsFile should be the
    same. The columns are as follows:
    ImageId TagID
    
    ImageLocationsFile='../data/ImageLocationsFile.txt'; %Output. Contains only IDs    
    This file has one less columns as the locationsFile Patrick supplied.
    The image name column (col 1) is replaced by ImageID.
    lattitude and longitude columns are replaced by one LocationID column.
    LocationID comes from IDvsLocationFile.
    The columns of this file are as follows:
    ImageID	User	timeTaken	LocationID	accuracyLevel

2.  Run constructTagSimilarityMatrix
    The program takes IDvsTagFile as its input and outputs the similarity
    matrix in sparse format in OutputSimilarityFile.
    IDvsTagFile='../data/IDvsTag.map'; %Input
    OutputSimilarityFile='../data/SimilarityMatrix_ForTags.txt'; %Output

3.  Run constructLocationSimilarityMatrix
    The program takes IDvsLocationFile as its input and outputs the
    similarity matrix in OutputSimilarityFile.
    IDvsLocationFile='../data/IDvsLocation.map'; %Input
    OutputSimilarityFile='../data/SimilarityMatrix_ForLocation.txt';%Output    

4.  Run constructVectorsFromImages
    This will generate vectors for each image.
    inputDir='../dump'; %input
    IDvsImageFile = '../data/IDvsImage.map'; %input. 
    outputDir='../imageVectorFiles'; %output

5.  Run constructImageSimilarityMatrix
    inputDir='../imageVectorFiles'; %Input
    IDvsImageFile='../data/IDvsImage.map'; %Input
    OutputSimilarityFile='../data/SimilarityMatrix_ForImages.txt'; %Output
