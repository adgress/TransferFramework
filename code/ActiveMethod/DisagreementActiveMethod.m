classdef DisagreementActiveMethod < EntropyActiveMethod
    %DISAGREEMENTACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = DisagreementActiveMethod(configs)            
            obj = obj@EntropyActiveMethod(configs);            
        end
        function [scores] = getScores(obj,input,results,s)
            
            unlabeledInds = ~input.train.isLabeled();
            transferPred = results.yPred(unlabeledInds);
            preTransferPred = s.preTransferResults.yPred(unlabeledInds);
            
            disagrees = find(transferPred ~= preTransferPred);
            %disagreesPerm = disagrees(randperm(length(disagrees)));
            %scores = 1:length(disagrees);
            scores = -ones(length(unlabeledInds),1);
            disagreeScores = randperm(length(disagrees));
            disagreeScores = disagreeScores ./ max(disagreeScores);
            scores(disagrees) = disagreeScores;                                
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'Disagreement';
        end  
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
    end
    
end

