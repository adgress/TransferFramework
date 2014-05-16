function [ myData ] = normalize(origninalData)
%NORMALIZE Summary of this function goes here
%   Detailed explanation goes here
    muo = mean( origninalData( :, 1:end) );
    stdo = std( origninalData( :, 1:end) );
    stdo2 = 1 ./ stdo;
    data = [ (origninalData(:,1:end) - ones(length(origninalData),1)*muo ) * diag(stdo2)     origninalData(:,end) ];
    myData=data;
end

