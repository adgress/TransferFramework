classdef MethodTransferMeasure < TransferMeasure
    %METHODTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = MethodTransferMeasure(configs)
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@TransferMeasure(configs);
        end
        
        function [measureResults,savedData] = computeMeasure(obj,source,target,...
                options,savedData)            
            learner = obj.get('learner'); 
            measureMetadata = struct();
            
            combined = target;
            if obj.get('useSourceForTransfer')
                combined = DataSet.Combine(combined,source{:});
            end
            input = struct();
            input.train = combined;
            input.test = [];
            results = learner.trainAndTest(input);
            
            measureResults = GraphMeasureResults(); 
            measureResults.score = results.learnerMetadata.cvAcc;
            measureResults.percCorrect = results.learnerMetadata.cvAcc;            
            measureResults.yPred = results.yPred;
            measureResults.yActual = results.yActual;
            n = num2str(measureResults.score);
            if obj.get('useSourceForTransfer')
                display(['Transfer CV: ' n]);
            else
                display(['Pre-Transfer CV: ' n]);
            end
        end
        function [name] = getPrefix(obj)
            name = ['TransferMeasure:' obj.get('learner').getPrefix()];
        end
    end
    
end

