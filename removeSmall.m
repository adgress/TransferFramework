function [] = removeSmall
    c = getProjectConstants();
    currDir = pwd;
    d = c.projectDir;
    cd(d);
    D = dir();
    for idx=1:length(D);
        d = D(idx);
        if ~d.isdir || isempty(strfind(d.name,'results'))
            continue;
        end
        recursiveRemoveSmall(d.name);
    end
    cd(currDir);
end

function [] = recursiveRemoveSmall(currDir)
    p = pwd;
    cd(currDir);
    D = dir();
    for idx=1:length(D)
        d = D(idx);
        if strcmp(d.name,'small')
            rmdir(d.name,'s');
        elseif d.isdir && ...
                ~(strcmp(d.name,'.') || strcmp(d.name,'..'))
            recursiveRemoveSmall(d.name);
        end
    end
    cd(p);
end