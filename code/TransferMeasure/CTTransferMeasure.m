classdef CTTransferMeasure < TransferMeasure
    %TRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = CTTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
            obj.set('saveFeatures',true);
        end
        
        function [fu] = runLabelPropagation(obj,distMat)
            useHF = false;
            if obj.has('sigmaScale')
                sigma = obj.get('sigmaScale')*distMat.meanDistance;
            else
                useMeanSigma = obj.configs.get('useMeanSigma');
                [sigma, bestScore,bestAcc] = GraphHelpers.autoSelectSigma(...
                    distMat,useMeanSigma,useHF);
            end
            rbfKernel = Helpers.distance2RBF(distMat.W,sigma);
            [fu,~] = GraphHelpers.RunLLGC(rbfKernel,distMat.Y,obj.get('alpha'));            
            Helpers.AssertInvalidPercent(fu,.1);
        end
        
        function [measureResults] = computeMeasure(obj,source,target,...
                options)            
            tic
            distMat = obj.createDistanceMatrix(source,target,options);
            distMatSourceProp = distMat.copy();
            distMatTargetProp = distMat.copy();
            
            distMatTargetProp.clearLabels(distMatTargetProp.isSource());                        
            toClear = distMatSourceProp.isTarget();
            if options.has('classesToKeep')
                toClear = toClear & ~distMatSourceProp.isClass(options.get('classesToKeep'));
            end
            distMatSourceProp.clearLabels(toClear);
            
            distMatSourceProp.swapSourceAndTarget();
            fuSourceProp = obj.runLabelPropagation(distMatSourceProp);
            distMatSourceProp.swapSourceAndTarget();
            fuTargetProp = obj.runLabelPropagation(distMatTargetProp);            

            measureResults = GraphMeasureResults();
            measureResults.measureMetadata.fuSourceProp = sparse(fuSourceProp);
            measureResults.measureMetadata.fuTargetProp = sparse(fuTargetProp);
            Helpers.AssertInvalidPercent(fuSourceProp,.1);
            Helpers.AssertInvalidPercent(fuTargetProp,.1);
            measureResults.dataType = distMat.type;
            measureResults.yActual = distMat.Y;
            if obj.get('saveFeatures')
                measureResults.sources = source;
                measureResults.sampledTrain = target;
            end
            toc
        end    
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'saveFeatures'};
        end  
        
        function [name] = getPrefix(obj)
            name = 'CT';
        end                        
    end
    
end

