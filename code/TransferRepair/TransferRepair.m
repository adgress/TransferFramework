classdef TransferRepair < Saveable
    %TRANSFERREPAIR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
        
    methods
        function [obj] = TransferRepair(configs)
            obj = obj@Saveable(configs);
        end
        function [d] = getDirectory(obj)
            d = 'REP';
        end
        
        function [repairedInput,metadata,savedData] = ...
                repairTransfer(obj,input,targetScores,savedData)
            metadata = struct();
            metadata.targetScores = targetScores;
            percToRemove = obj.configs('percToRemove');
            
            repairedInput = input;
            strategy = obj.configs('strategy');
            
            isLabeledSource = input.train.type == Constants.SOURCE & input.train.Y > 0;
            sourceInds = find(isLabeledSource);
            numSource = length(sourceInds);
            numToPrune = ceil(percToRemove*numSource);
            if isequal(strategy,'None')
                return;
            end
            if isequal(strategy,'Random')
                toRemove = randperm(numSource,numToPrune);
                repairedInput.train.remove(sourceInds(toRemove));
                return;
            end            
            [scores,predicted] = max(targetScores,[],2);
            labeledTargetTrainInds = find(input.train.Y > 0 & ...
                input.train.type == Constants.TARGET_TRAIN);
            correctLabels = input.train.Y(labeledTargetTrainInds);
            isLabeledSource = input.train.type == Constants.SOURCE & input.train.Y > 0;
            if isequal(strategy,'Exhaustive')
                measureObj = TransferMeasure.ConstructObject(...
                    obj.configs('repairTransferMeasure'),obj.configs);
                measureObj.configs('quiet') = 1;
                sourceData = input.train.getSourceData();
                targetData = input.train.getTargetData();
                targetData = DataSet.Combine(targetData,...
                    input.test);
                targetData.removeTestLabels();
                
                [PMTVal,~,~,~] = measureObj.computeMeasure(sourceData,...
                    targetData,struct(),savedData);                
                
                
                labeledSourceInds = find(input.train.Y > 0 & input.train.type == Constants.SOURCE);
                repairedScores = zeros(length(labeledSourceInds),1);
                for sourceIndItr=1:ceil(length(labeledSourceInds))
                    sourceInd = labeledSourceInds(sourceIndItr);
                    savedY = input.train.Y(sourceInd);
                    input.train.Y(sourceInd) = -1;
                    [r] = savedData.o.trainAndTest(input,savedData.experiment,savedData.methodSavedData);
                    repairedScores(sourceIndItr) = mean(r.testPredicted == r.testActual);
                    input.train.Y(sourceInd) = savedY;
                end
                %{
                labeledSourceInds = find(sourceData.Y > 0);
                repairedScores = zeros(length(labeledSourceInds),1);
                source2unlabeledTarget = Helpers.CreateDistanceMatrix(sourceData.X,...
                    targetData.X(targetData.Y < 1,:));
                for sourceIndItr=1:length(labeledSourceInds)
                    sourceInd = labeledSourceInds(sourceIndItr);
                    savedY = sourceData.Y(sourceInd);
                    sourceData.Y(sourceInd) = -1;
                    repairedScores(sourceIndItr) = measureObj.computeMeasure(sourceData,...
                        targetData,struct(),savedData);
                    sourceData.Y(sourceInd) = savedY;
                end
                deltaScores = repairedScores - savedData.postTransferMeasureVal;
                [sortedDeltaScores,sortedDeltaScoreInds] = sort(deltaScores,'descend');
                meanDistances = mean(source2unlabeledTarget,2);
                    %}

                deltaScores = repairedScores;
                [sortedDeltaScores,sortedDeltaScoreInds] = sort(deltaScores,'ascend');
                sourceIndsToPrune = sortedDeltaScoreInds(1:numToPrune);
                sourceIndsInTrain = find(repairedInput.train.type == Constants.SOURCE);
                indsToPrune = sourceIndsInTrain(sourceIndsToPrune);
                
                sourceData.Y(sourceIndsToPrune) = -1;
                [PTMValAfterPruning,~,~,~] =  measureObj.computeMeasure(sourceData,...
                        targetData,struct(),savedData);
                Helpers.PrintNum('TransferMeasure PTMVal: ', savedData.postTransferMeasureVal);
                Helpers.PrintNum('Pre-Pruning PTMVal: ', PMTVal);
                Helpers.PrintNum('Post-Pruning PTMVal: ',PTMValAfterPruning);
                    
            elseif isequal(strategy,'NNPrune') || isequal(strategy,'AddvancedNNPrune')
                dataSet = DataSet.Combine(input.train,input.test);
                dataSet.removeTestLabels();
                useAdvanced = isequal(strategy,'AddvancedNNPrune');                                
                isIncorrect = predicted ~= correctLabels;
                metadata.isIncorrect = isIncorrect;
                correctLabelScores = Helpers.SelectFromRows(targetScores,correctLabels);
                
                [sortedCorrectScores,sortedInds] = sort(correctLabelScores,'ascend');                
                
                incorrectInds = labeledTargetTrainInds(isIncorrect);
                correctTargetLabels = input.train.Y(incorrectInds);
                
                %numIncorrectToUse = 5;
                %trainIndsToUse = sortedInds(1:numIncorrectToUse );
                %correctTargetLabels = correctLabels(trainIndsToUse);
                if obj.configs('useECT')
                    sigma = obj.configs('sigma');
                    W = Helpers.CreateDistanceMatrix(input.train.X);
                    W = Helpers.distance2RBF(W,sigma);
                    D = diag(sum(W));
                    nD = sqrt(inv(D));
                    L = eye(size(W)) - nD*W*nD;
                    invL = pinv(L);
                    distMat = Kernel.ComputeKernelDistance(invL);
                end
                if useAdvanced
                    error('Make sure we''re using the correct indices!');
                    %trainIndsToUse = labeeldTargetTrainInds;                    
                    sourceLabels = input.train.Y(isLabeledSource);
                    
                    %TODO: Replace this with coincidence matrix?
                    sourceLabelsRep = repmat(sourceLabels',length(correctLabels),1);
                    sourceLabelsRep = sourceLabelsRep(trainIndsToUse,:);
                    targetLabelsRep = repmat(correctLabels,1,length(sourceLabels));                    
                    targetLabelsRep = targetLabelsRep(trainIndsToUse,:);
                    if obj.configs('useECT')
                        distMat = distMat(trainIndsToUse,isLabeledSource);
                    else
                        distMat = Helpers.CreateDistanceMatrix(...
                            input.train.X(trainIndsToUse,:),...
                            input.train.X(isLabeledSource,:));
                    end
                    isCorrectRep = sourceLabelsRep == targetLabelsRep;
                    isIncorrectRep = ~isCorrectRep;
                    incorrectDistances = distMat.*isIncorrectRep;                    
                    incorrectSourceScores = sum(incorrectDistances);
                    [sortedScores,sortedScoreInds] = sort(incorrectSourceScores,'ascend');
                    sourceInds = find(isLabeledSource);
                    indsToPrune = sourceInds(sortedScoreInds);
                else
                    useOnly1 = 1;
                    labeledTargetIndsToFocusOn = isIncorrect;
                    if useOnly1
                        display('Only using 1 incorrect target!');
                        
                        incorrectInds = labeledTargetTrainInds(sortedInds(1));
                        correctTargetLabels = input.train.Y(incorrectInds);
                        
                        trainIndsToUse = incorrectInds;
                        labeledTargetIndsToFocusOn = zeros(length(correctLabels),1);
                        labeledTargetIndsToFocusOn(sortedInds(1)) = 1;
                    end
                    if obj.configs('useECT')
                        distMat = distMat(trainIndsToUse,:);
                        %{
                        d1 = distMat;                        
                        d2 = Helpers.CreateDistanceMatrix(...
                            input.train.X(trainIndsToUse,:),...
                            input.train.X);
                        [d1Vals,I1] = sort(d1,'ascend');
                        [d2Vals,I2] = sort(d2,'ascend');
                        [I1' I2']
                        %}
                    else
                        distMat = Helpers.CreateDistanceMatrix(...
                            input.train.X(trainIndsToUse,:),...
                            input.train.X);
                    end
                    [sortedD,sortedDInds] = sort(distMat,2);
                    i = 1;
                    indsToPrune = [];
                    while length(indsToPrune) < numToPrune;
                        currInds = sortedDInds(:,i);                    
                        actualLabels = input.train.Y(currInds);
                        isMismatch = correctTargetLabels ~= actualLabels;
                        isNNSource = isLabeledSource(currInds);                    
                        shouldPrune = currInds(isNNSource & isMismatch & ...
                            actualLabels > 0);
                        indsToPrune = [indsToPrune ; shouldPrune];
                        if length(indsToPrune) >= numToPrune
                            indsToPrune = unique(indsToPrune);
                        end
                        i = i + 1;
                    end   
                end                
                indsToPrune = indsToPrune(1:numToPrune);                
                metadata.correctLabelScores = correctLabelScores;
                metadata.trainIndsToUse = trainIndsToUse;
                metadata.labeledTargetIndsToFocusOn = labeledTargetIndsToFocusOn;
                metadata.labeledTargetTrainInds = labeledTargetTrainInds;
                %metadata.incorrectTarget = input.train.Y > 0 & input.train.Y ~= 
                %repairedInput.train.remove(indsToPrune);
                assert(sum(repairedInput.train.Y(indsToPrune) == -1) == 0);
                assert(sum(repairedInput.train.type(indsToPrune) ~= Constants.SOURCE) == 0);                
            else
                error(['Unknown Strategy: ' strategy]);
            end
            metadata.indsToPrune = indsToPrune;
            repairedInput.train.Y(indsToPrune) = -1;
            %[metadata.trainIndsToUse metadata.labeledTargetTrainInds(find(metadata.labeledTargetIndsToFocusOn))]
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'TR';
        end        
        function [nameParams] = getNameParams(obj)
            nameParams = {'strategy','percToRemove','numIterations','useECT','fixSigma','saveINV'};
        end        
    end    
end

