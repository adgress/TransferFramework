function [X,Y] = normalizeLocations(allLocs)
    X = allLocs(:,1);
    Y = allLocs(:,2);
    X = X - min(X);
    Y = Y - min(Y);    
    X = X./max(X);
    Y = Y./max(Y);
    X = .95*(X-mean(X)) + mean(X);
    Y = .95*(Y-mean(Y)) + mean(Y);
end