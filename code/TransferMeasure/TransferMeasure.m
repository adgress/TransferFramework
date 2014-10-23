classdef TransferMeasure < Saveable
    %TRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TransferMeasure(configs)
            obj = obj@Saveable(configs);
        end
        
        function [W] = createDistanceMatrix(obj, source, target, savedData)
            XallCombined = [source.X ; target.X];  
            if obj.configs.get('zscore')
                XallCombined = zscore(XallCombined);
            end
            YCombined = [source.Y ; target.Y];
            typeCombined = [source.type ; target.type];
            if exist('savedData','var') && isfield(savedData,'W')
                W = savedData.W;
            else
                W = Kernel.Distance(XallCombined);                    
                if exist('savedData','var')
                    savedData.W = W;
                end
            end
            W = DistanceMatrix(W,YCombined,typeCombined); 
            W.prepareForSourceHF();                      
            if ~obj.configs.get('useSourceForTransfer')                
                W.removeInstances(W.isSource());       
            end
        end
        
        function [measureResults,savedData] = ...
                computeGraphMeasure(obj,source,target,options,...
                useHF,savedData)                
            measureMetadata = struct();
            targetWithLabels = target.Y > 0;
            if sum(targetWithLabels) == 0 || ...
                sum(targetWithLabels) <= max(target.Y)
                error('TODO');
                return;
            end            
            if isfield(options,'distanceMatrix')
                error('Not yet implemented!');
                W = options.distanceMatrix;                
            else                
                if exist('savedData','var') && isfield(savedData,'W')
                    [W] = obj.createDistanceMatrix(source, target, savedData);
                else
                    [W] = obj.createDistanceMatrix(source, target);
                end
            end                                    
            if isKey(obj.configs,'sigma')
                error('Why are we using this sigma?');
                sigma = obj.configs.get('sigma');
            else
                useMeanSigma = obj.configs.get('useMeanSigma');
                [sigma,~,~] = GraphHelpers.autoSelectSigma(W,useMeanSigma,useHF);            
            end
            measureMetadata.sigma = sigma;
            rerunLOOCV = 1;
            if rerunLOOCV
                rbfKernel = Helpers.distance2RBF(W.W,sigma);
                distMat = DistanceMatrix(rbfKernel,W.Y,W.type);
                if exist('savedData','var')
                    [score, percCorrect,Ypred,Yactual,labeledTargetScores,savedData] ...
                        = GraphHelpers.LOOCV(distMat,useHF,savedData);
                else
                    [score, percCorrect,Ypred,Yactual,labeledTargetScores] ...
                        = GraphHelpers.LOOCV(distMat,useHF);
                end
            else
                error('TransferMeasure: Not rerunning LOOCV');
            end                    
            if ~obj.configs.get('quiet')
                if obj.configs.get('useSoftLoss')
                    val = score;                                
                else
                    val = percCorrect;                
                end  
                obj.displayMeasure(val);
            end                        
            measureResults = GraphMeasureResults();            
            measureResults.score = score;
            measureResults.percCorrect = percCorrect;
            measureResults.yPred = Ypred;
            measureResults.yActual = Yactual;
            measureResults.labeledTargetScores = labeledTargetScores;            
            measureResults.measureMetadata = measureMetadata;
            measureResults.perLabelMeasures = [];
            measureResults.dataType = DataSet.TargetTrainType(length(Ypred));
            
            measureResults.sources = {source};
            measureResults.sampledTrain = target.getTargetTrainData();
            measureResults.test = target.getTargetTestData();            
            
            assert(isempty(find(isnan(measureResults.Ypred))));
        end         
        
        function [d] = getDirectory(obj)
            d = 'TM';
        end
        function [] = displayMeasure(obj,val)
            display([obj.getPrefix() ' TransferMeasure: ' num2str(val)]); 
        end
    end
    
    methods(Abstract)
        [val,perLabelMeasures,metadata] = computeMeasure(obj,source,target,options)        
    end
    
end

