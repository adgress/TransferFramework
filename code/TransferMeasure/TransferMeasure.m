classdef TransferMeasure < Saveable
    %TRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TransferMeasure(configs)
            obj = obj@Saveable(configs);
            obj.set('useSourceForTransfer',true);
        end
        
        function [W,savedData] = createDistanceMatrix(obj, sources, target, options, makeRBF, savedData)
            if isa(sources,'cell')
                source = DataSet.Combine(sources{:});
            else
                source = sources;
            end            
            YCombined = [source.Y ; target.Y];
            typeCombined = [source.type ; target.type];
            if exist('savedData','var') && isfield(savedData,'W')
                W = savedData.W;            
            else
                Xall = [source.X ; target.X];  
                if obj.get('zscore')
                    Xall = zscore(Xall);
                end
                if obj.get('useSeparableDistanceMatrix')
                    assert(makeRBF);
                    sigmaScale = obj.get('sigmaScale');
                    W = zeros(size(Xall,1));
                    for featureIdx=1:size(Xall,2)
                        W_i = full(Helpers.CreateDistanceMatrix(Xall(:,featureIdx)));
                        sigma_i = sigmaScale*mean(W_i(:));          
                        if sigma_i == 0
                            continue;
                        end                        
                        a = Helpers.distance2RBF(W_i,sigma_i)./size(Xall,2);
                        %a = W_i.^2;
                        %a = -a ./ (2*sigma_i^2);
                        assert(all(~isnan(a(:))));
                        assert(all(~isinf(a(:))));
                        W = W + a;
                    end
                    %W = exp(W);
                else
                    W = Kernel.Distance(Xall);                                        
                end
                if exist('savedData','var')
                    savedData.W = W;
                end
            end
            trueYCombined = [source.trueY ; target.trueY];
            instanceIDsCombined = [source.instanceIDs ; target.instanceIDs];
            W = DistanceMatrix(W,YCombined,typeCombined,trueYCombined,...
                instanceIDsCombined); 
            %W.prepareForSourceHF();                      
            if ~obj.configs.get('useSourceForTransfer')                
                W.removeInstances(W.isSource());       
            end
        end
        
        function [measureResults,savedData] = ...
                computeGraphMeasure(obj,source,target,options,...
                useHF,savedData)       
            makeRBF = true;
            measureMetadata = struct();
            targetWithLabels = target.Y > 0;
            if sum(targetWithLabels) == 0 || ...
                sum(targetWithLabels) <= target.numClasses
                error('TODO');
                return;
            end            
            if isfield(options,'distanceMatrix')
                error('Not yet implemented!');
                W = options.distanceMatrix;                
            else                
                if exist('savedData','var')
                    [W,savedData] = obj.createDistanceMatrix(source, target, options, makeRBF, savedData);
                else
                    [W] = obj.createDistanceMatrix(source, target, makeRBF, options);
                end
            end      
            alpha = obj.get('alpha');
            if isKey(obj.configs,'sigma')
                error('Why are we using this sigma?');
                sigma = obj.configs.get('sigma');
            elseif obj.has('sigmaScale')
                sigma = obj.get('sigmaScale')*W.meanDistance;
            else
                useMeanSigma = obj.configs.get('useMeanSigma');
                [sigma,~,~] = GraphHelpers.autoSelectSigma(W,useMeanSigma,useHF);            
            end
            measureMetadata.sigma = sigma;
            rerunLOOCV = 1;            
            if rerunLOOCV
                if makeRBF
                    rbfKernel = W.W;
                else
                    rbfKernel = Helpers.distance2RBF(W.W,sigma);
                end
                distMat = DistanceMatrix(rbfKernel,W.Y,W.type,W.trueY,W.instanceIDs);
                if exist('savedData','var')
                    [score, percCorrect,Ypred,Yactual,labeledTargetScores,savedData] ...
                        = GraphHelpers.LOOCV(distMat,useHF,alpha,savedData);
                else
                    [score, percCorrect,Ypred,Yactual,labeledTargetScores] ...
                        = GraphHelpers.LOOCV(distMat,useHF,alpha);
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
            
            %{
            measureResults.sources = {source};
            measureResults.sampledTrain = target.getTargetTrainData();
            measureResults.test = target.getTargetTestData();            
            %}
            assert(isempty(find(isnan(measureResults.yPred))));
        end         
        
        function [d] = getDirectory(obj)
            d = 'TM';
        end
        function [] = displayMeasure(obj,val)
            display([obj.getPrefix() ' TransferMeasure: ' num2str(val)]); 
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
    
    methods(Abstract)
        [val,perLabelMeasures,metadata] = computeMeasure(obj,source,target,options)        
    end
    
end

