function [] = makeSyntheticData()

n = 500;
p = 50;
sigma = .1;

numNonZero = p/10;
folder = 'Data/syntheticSparse/';
target = struct();
target.sigma = 1;
source = struct();
source.sigma = 1;

[source.X,source.Y,source.beta,source.beta0] = SyntheticDataGenerator.createLinearData(n,p,...
    numNonZero,[],sigma);
isZero = source.beta == 0;
[target.X,target.Y,target.beta,target.beta0] = SyntheticDataGenerator.createLinearData(n,p,2*numNonZero,...
    isZero,sigma);



suffix = ['n=' num2str(n) ',p=' num2str(p) ',sigma=' num2str(sigma)];
sourceFile = [folder 'source,' suffix '.mat'];
targetFile = [folder 'target,' suffix '.mat'];
Helpers.MakeDirectoryForFile(sourceFile);
data = source;
save(sourceFile,'data');
data = target;
save(targetFile,'data');
end

