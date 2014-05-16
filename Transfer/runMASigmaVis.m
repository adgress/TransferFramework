function [] = runMASigmaVis()
    prefix = 'results/';
    transfer = 'A2C';
    method = 'ma';
    params = {};
    values = {{.001 .01 .1 1}};
    files = {};
    for i=1:numel(params)
        p = params{i};
        vals = values{i};
        filePrefix = [prefix method transfer];
        for j=1:numel(vals)
            v = vals{j};
            vStr = v;
            if ~isa(vStr,'char')
                vStr = num2str(vStr);
            end
            fileName = [filePrefix '_' p '=' vStr '.mat'];
            files{end+1} = fileName;
        end
    end
    files{end+1} = [prefix 'ma' transfer '.mat'];
    files{end+1} = [prefix 'transfer' transfer '.mat'];
    files{end+1} = [prefix 'fuse' transfer '.mat'];
    files{end+1} = [prefix 'source' transfer '.mat'];
    runVisualization(0,1,files);
end