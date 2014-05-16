function [] = printCondNumber(X,varName)
    display(sprintf('Cond(%s) = %2.2e',varName,cond(X)));
end