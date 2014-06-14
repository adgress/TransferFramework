classdef LLGCTransferMeasure < TransferMeasure
    %SCTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,perLabelMeasures,metadata,savedData] = computeMeasure(obj,source,target,...
                options,savedData)
            useHF = false;
            if exist('savedData','var')
                [score,percCorrect,Ypred,Yactual,labeledTargetScores,val,metadata,savedData] = ...
                    obj.computeGraphMeasure(source,target,options,...
                    useHF,savedData);   
            else
                [score,percCorrect,Ypred,Yactual,labeledTargetScores,val,metadata] = ...
                    obj.computeGraphMeasure(source,target,options,...
                    useHF);
            end
            metadata.labeledTargetScores = labeledTargetScores;
            perLabelMeasures = [];
        end                    
        
        function [name] = getPrefix(obj)
            name = 'LLGC';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'useSoftLoss','useMeanSigma'};
        end
    end    
end

