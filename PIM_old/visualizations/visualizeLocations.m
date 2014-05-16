function [f] = visualizeLocations(locationsKeptIndices)    
    addpath('..');
    load results/clustering-with-clusters.mat
    locationsToPrint = {};
    locationsKept = clustering.data.locationsKept;
    locationsToPrint{1} = [61,57,77,73];
    locationsToPrint{2} = [24,25,66,46];
    locationsToPrint{3} = [86,67,88,31];
    imageLocationsToPrint = {};
    imageLocationsToPrint{1} = {[0.502698,0.499101],[0.502698,0.499101],[0.502698,0.499101],[0.502698,0.499101]};
    imageLocationsToPrint{2} = {[0.143044,0.947200],[0.143044,0.947200],[0.143571,0.947014],[0.143044,0.947200]};
    imageLocationsToPrint{3} = {[0.515124,0.495579],[0.516555,0.495068],[0.516555,0.495068],[0.516555,0.495068]};
    
    locToCluster = containers.Map;
    for i=1:numel(locationsToPrint)
        locations = locationsToPrint{i};
        for j=1:numel(locations)
            locToCluster(num2str(locations(j))) = i;
        end
    end
    addpath('pimData');
    allLocs = loadLocationsFile();    
    longitudes = allLocs(:,1);
    lattitudes = allLocs(:,2);
    lonRange = [min(longitudes) max(longitudes)];
    latRange = [min(lattitudes) max(lattitudes)];
    [lonRange(1) latRange(1)]
    [lonRange(2) latRange(2)]
    [X,Y] = normalizeLocations(allLocs);
    
    if nargin < 1        
        %locationsKeptIndices = 1:numel(X);
        locationsKeptIndices = locationsKept;
    end
    showLocation = zeros(numel(X),1);
    showLocation(locationsKeptIndices) = 1;
    f = figure();
    im = imread('map-cropped.png');
    imshow(im);
    clusterColors = hsv(10);
    hold on;
    for i=1:numel(X)
        if ~showLocation(i)
            continue;
        end
        xi = X(i);
        yi = Y(i);
        if isKey(locToCluster,num2str(i))
            clusterIdx = locToCluster(num2str(i));
            text('units','normalized','position',[xi yi],'fontsize',20,...
                'string',num2str(i),'color',clusterColors(clusterIdx,:));
        else
            locID = sum(showLocation(1:i));
            clusterIdx = clustering.loc_idx(locID);
            text('units','normalized','position',[xi yi],'fontsize',10,...
                'string','x','color',clusterColors(clusterIdx,:));
            %text('units','normalized','position',[xi yi],'fontsize',10,'string',num2str(i))
        end
    end
    for i=1:numel(imageLocationsToPrint)
        imageLocs = imageLocationsToPrint{i};
        for j=1:numel(imageLocs)
            imageLoc = imageLocs{j};
            text('units','normalized','position',imageLoc,'fontsize',10,...
                'string','I','color',clusterColors(i,:));
        end
    end
    print(f,'-djpeg','locationMap.png');
    saveas(f,'locationMap.fig');
    hold off;
end