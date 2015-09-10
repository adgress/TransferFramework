classdef VarianceEstimateActiveMethod < ActiveMethod
    %VARIANCEESTIMATEACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = VarianceEstimateActiveMethod(configs)            
            obj = obj@ActiveMethod(configs);
        end
        function [scores] = getScores(obj,input,results,s)
            varEstimates = [];
            densityEstimates = [];
            sigma = input.learner.get('sigma');
            isLabeled = input.train.isLabeled();
            isUnlabeled = find(~input.train.isLabeled());
            W = Helpers.CreateDistanceMatrix(input.train.X);
            %Wu2L = W(I,~I);            
            %minDists = min(Wu2L,[],2);
            Wrbf = Helpers.distance2RBF(W,sigma);
            for i=1:length(isUnlabeled)
                idx = isUnlabeled(i);
                y = results.trainFU(idx);
                diff = (results.trainActual(isLabeled) - y).^2;
                weightedDiff = diff' .* Wrbf(idx,isLabeled);
                varEstimates(i) = sum(weightedDiff);
                densityEstimates(i) = sum(Wrbf(idx,isLabeled))/sum(isLabeled);
            end            
            varEstimates = varEstimates';
            densityEstimates = densityEstimates';
            %full([varEstimates results.trainFU(isUnlabeled) input.train.trueY(isUnlabeled)])
            scores = 1 ./ densityEstimates;
            %densityEstimates
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'VarEstimate';
        end    
    end
    
end

