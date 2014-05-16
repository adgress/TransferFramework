function [allTags] = loadTagsFile()
    file = 'IDvsTag.map';
    f = fopen(file);
    allTags = textscan(f,'%d %s');
    fclose(f);
end