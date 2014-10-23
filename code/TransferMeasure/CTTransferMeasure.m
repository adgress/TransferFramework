classdef CTTransferMeasure < TransferMeasure
    %TRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = CTTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [fu] = runLabelPropagation(obj,distMat)
            useHF = false;
            useMeanSigma = obj.configs.get('useMeanSigma');
            [sigma, bestScore,bestAcc] = GraphHelpers.autoSelectSigma(...
                distMat,useMeanSigma,useHF);
            rbfKernel = Helpers.distance2RBF(distMat.W,sigma);
            [fu,~] = GraphHelpers.RunLLGC(rbfKernel,distMat.Y);            
            Helpers.AssertInvalidPercent(fu,.1);
        end
        
        function [measureResults] = computeMeasure(obj,source,target,...
                options)            
            
            distMat = obj.createDistanceMatrix(source,target);
            distMatSourceProp = distMat.copy();
            distMatTargetProp = distMat.copy();
            
            distMatSourceProp.clearLabels(distMatSourceProp.isTarget());                        
            distMatTargetProp.clearLabels(distMatTargetProp.isSource());
            
            distMatSourceProp.swapSourceAndTarget();
            fuSourceProp = obj.runLabelPropagation(distMatSourceProp);
            distMatSourceProp.swapSourceAndTarget();
            fuTargetProp = obj.runLabelPropagation(distMatTargetProp);            

            measureResults = GraphMeasureResults();
            measureResults.measureMetadata.fuSourceProp = fuSourceProp;
            measureResults.measureMetadata.fuTargetProp = fuTargetProp;
            Helpers.AssertInvalidPercent(fuSourceProp,.1);
            Helpers.AssertInvalidPercent(fuTargetProp,.1);
            measureResults.dataType = distMat.type;
            measureResults.yActual = distMat.Y;
            %measureResults.sources = {source};
            %measureResults.sampledTrain = target;
        end    
        
        function [name] = getPrefix(obj)
            name = 'CT';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end    
        function [displayName] = getDisplayName(obj)
            displayName = obj.getResultFileName(',',false);
            if obj.has('measureLoss')
                measureLoss = obj.get('measureLoss');
                measureLossName = measureLoss.getDisplayName();
                displayName = [displayName ';' measureLossName];
            end
        end
    end
    
end

