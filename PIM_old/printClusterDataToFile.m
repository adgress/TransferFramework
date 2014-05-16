function [] = printClusterDataToFile(directory,images,tags,locations,distances,data)

    imageIDs = data.imagesKept(images);
    tagIDs = data.wordsKept(tags);
    locationIDs = data.locationsKept(locations);

    allLocs = loadLocationsFile();        
    [X,Y] = normalizeLocations(allLocs);
    
    fileName = 'cluster.txt';        
    file = fopen([directory fileName],'w');
    fprintf(file,'IMAGES:\n');
    index = 0;
    fprintf(file,'Image Locations: {');
    for i=1:numel(imageIDs)
        locID = find(data.imageLocationsSimMat(images(i),:));
        location = data.locationsKept(locID);
        fprintf(file,'[%f,%f]',X(location),Y(location));
        if i~=numel(imageIDs)
            fprintf(file,',');
        end
    end
    fprintf(file,'}\n');
    for i=1:numel(imageIDs)
        fprintf(file,'\t%d, %2.2e\n',imageIDs(i),distances(index+i));
        tagIndices = find(data.imageTagsSimMat(images(i),:));
        fprintf(file,'\t\t');
        for j=1:numel(tagIndices)
            fprintf(file,'%s,',data.wordsKept{tagIndices(j)});            
        end
        fprintf(file,'\n');
        location = find(data.imageLocationsSimMat(images(i),:));
        fprintf(file,'\t\t%d\n',data.locationsKept(location));
    end
    index = index + numel(imageIDs);
    fprintf(file,'TAGS:\n');
    for i=1:numel(tagIDs)
        fprintf(file,'\t%s, %2.2e\n',tagIDs{i},distances(index+i));
    end
    fprintf(file,'LOCATIONS:\n');
    index = index + numel(tagIDs);
    fprintf(file,'[');
    for i=1:numel(locationIDs)
        fprintf(file,'%d',locationIDs(i));
        if i~=numel(locationIDs)
            fprintf(file,',');
        end
    end
    fprintf(file,']\n');
    for i=1:numel(locationIDs)
        fprintf(file,'\t%d, %2.2e\n',locationIDs(i),distances(index+i));
    end
    for j=1:numel(imageIDs)
        source = ['images/' num2str(imageIDs(j)) '.pgm'];
        I = imread(source);
        %copyfile(source,directory);
        imwrite(I,[directory '/' num2str(imageIDs(j)) '.jpg']);
    end
    fclose(file);
end