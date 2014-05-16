function [allLocs] = loadLocationsFile()
    file = 'IDvsLocation.map';
    f = fopen(file);
    allLocs = textscan(f,'%d %f %f');
    allLocs = [allLocs{2} allLocs{3}];
    fclose(f);
end