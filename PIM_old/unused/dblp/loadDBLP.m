function [dblp] = loadDBLP()
    if exist('dblp.mat','file')
        load dblp.mat;
        return;
    end
    dblp = struct();
    dblp.cikm = loadCSV('d-cikm.csv');
    dblp.icdm = loadCSV('d-icdm.csv');
    dblp.sdm = loadCSV('d-sdm.csv');
    dblp.kdd = loadCSV('d-sigkdd.csv');
    dblp.mod = loadCSV('d-sigmod.csv');
    dblp.vldb = loadCSV('d-vldb.csv');
    save dblp;
end

function [data] = loadCSV(file)
    A = load(file);
    data = sparse(30176,30176);    
    data(A(:,1),A(:,2)) = 1;
end