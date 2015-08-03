classdef QQEdgeExperimentConfigLoader < ExperimentConfigLoader
    %QQEDGEEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = QQEdgeExperimentConfigLoader(configs)
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@ExperimentConfigLoader(configs);
        end
        
        function [train,test,validate,featType] = getSplit(obj,index)
            [train,test,validate,featType] = getSplit@ExperimentConfigLoader(obj,index);
            pc = ProjectConfigs.Create();            
            numSteps = length(train.Y);
            Wqq = zeros(numSteps); 
            numEdges = .5*numSteps*(numSteps-1);
            edges = zeros(numEdges,2);
            idx = 1;
            for i=1:size(Wqq,1)
                for j = i+1:size(Wqq,1)
                    edges(idx,:) = [i j];
                    idx = idx + 1;
                end
            end
            I = randperm(numEdges);
            toUse = edges(I(1:ceil(numEdges*pc.QQEdges)),:);
            for idx=1:size(toUse,1)
                e = toUse(idx,:);
                Wqq(e(1),e(2)) = (train.trueY(e(1)) == train.trueY(e(2))) - .5;
            end
            Wqq = 2*Wqq;
            Wqq = Wqq + Wqq';
            train.W11 = Wqq;
            test.W11 = Wqq;
        end
        
        function [outputFileName] = getOutputFileName(obj)
            pc = ProjectConfigs.Create();
            [outputPrefix] = obj.getOutputFilePrefix();
            
            outputFileName = [outputPrefix '-QQedges=' num2str(pc.QQEdges) '.mat'];
            Helpers.MakeDirectoryForFile(outputFileName);
        end
    end
    
end

