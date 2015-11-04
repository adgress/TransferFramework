function [] = makeSyntheticPolynomialData()

n = 100;
sigma = .5;
targetDegree = 2;
sourceDegree = 3;
range = [1 2];
folder = 'Data/syntheticPolynomial/';
target = struct();
target.sigma = sigma;
target.degree = targetDegree;
source = struct();
source.sigma = sigma;
source.degree = sourceDegree;

[source.X,source.Y,source.trueY] = ...
    SyntheticDataGenerator.createPolynomialData(n,sourceDegree,range,sigma);
[target.X,target.Y,target.trueY] = ...
    SyntheticDataGenerator.createPolynomialData(n,targetDegree,range,sigma);

suffix = ['n=' num2str(n) ',degree=' num2str(sourceDegree) ',sigma=' num2str(sigma)];
sourceFile = [folder 'source,' suffix '.mat'];
suffix = ['n=' num2str(n) ',degree=' num2str(targetDegree) ',sigma=' num2str(sigma)];
targetFile = [folder 'target,' suffix '.mat'];
Helpers.MakeDirectoryForFile(sourceFile);
data = source;
save(sourceFile,'data');
data = target;
save(targetFile,'data');
close all;
scatter(source.X,source.Y);
hold on;
scatter(target.X,target.Y);
hold off;
end

