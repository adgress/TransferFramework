classdef Measure < Saveable
    %MEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = Measure(configs)
            if ~exist('configs','var')
                configs = [];
            end
            obj = obj@Saveable(configs);
        end
        function [valTrain,valTest] = computeTrainTestResults(obj,r)
            trainLabeled = r.yTrain > 0 & ~r.isValidation;
            trainAccVec = r.trainPredicted==r.trainActual;            
            trainAccVec = trainAccVec(trainLabeled);
            valTrain = mean(trainAccVec);
            valTest = sum(r.testPredicted==r.testActual)/...
                        numel(r.testPredicted);   
        end
        
        
        function [measureResults] = evaluate(obj,split)
            measureResults = struct();            
            
            if isa(split,'ActiveLearningResults')
                iterationResults = split.iterationResults;
                valTrain = [];
                valTest = [];
                preTransferValTrain = [];
                preTransferValTest = [];
                transferMeasures = [];
                preTransferMeasures = [];
                regs = [];
                bestRegs = [];
                cvAcc = [];
                divergence = zeros(length(iterationResults),1);
                for resultIdx=1:length(iterationResults)
                    if resultIdx > 1 && ~isempty(split.activeMetadata)
                        m = split.activeMetadata{resultIdx-1};
                        divergence(resultIdx) = m.divergence;
                    end
                    r = iterationResults{resultIdx};
                    if ~isempty(r)
                        [valTrain(resultIdx),valTest(resultIdx)] = ...
                            obj.computeTrainTestResults(r);
                    end
                    r2 = split.preTransferResults{resultIdx};
                    if ~isempty(r2)                        
                        [preTransferValTrain(resultIdx), ...
                            preTransferValTest(resultIdx)] = ...
                            obj.computeTrainTestResults(r2);                        
                        regs(resultIdx) = r2.learnerMetadata.reg;
                        cvAcc(resultIdx) = r2.learnerMetadata.cvAcc;
                        bestRegs(resultIdx) = r2.modelResults(argmax([r2.modelResults.testAcc])).reg;                        
                    end
                    if ~isempty(split.transferMeasureResults)
                        transferMeasures(resultIdx) = ...
                            split.transferMeasureResults{resultIdx}.percCorrect;
                    end
                    if ~isempty(split.preTransferMeasureResults)
                        preTransferMeasures(resultIdx) = ...
                            split.preTransferMeasureResults{resultIdx}.percCorrect;
                    end
                end
                hasTransfer = ~isempty(r);
                hasPreTransfer = ~isempty(r2);
                hasBoth = hasPreTransfer && hasTransfer;
                if hasBoth
                    transferDifference = ...
                        valTest - preTransferValTest;                
                    measureResults.learnerStats.transferDifference = transferDifference;
                end                
                measureResults.learnerStats.divergence = divergence;
                if hasPreTransfer
                    measureResults.learnerStats.preTransferValTrain = preTransferValTrain; 
                    measureResults.learnerStats.preTransferValTest = preTransferValTest;                
                    measureResults.learnerStats.regs = log10(regs);
                    measureResults.learnerStats.bestRegs = log10(bestRegs);
                    measureResults.learnerStats.regDiffs = abs(log10(bestRegs)-log10(regs));
                    measureResults.learnerStats.cvPerfDiff = abs(preTransferValTest-cvAcc);
                    measureResults.learnerStats.cvPerfDelta = cvAcc-preTransferValTest;
                    measureResults.learnerStats.cvAcc = cvAcc;
                    
                    desiredPerf = ProjectConfigs.desiredPerf;
                    measureResults.learnerStats.terminatedPerf = zeros(size(desiredPerf));
                    measureResults.learnerStats.numIterations = zeros(size(desiredPerf));
                    for idx=1:length(desiredPerf)
                        hasDesiredPerf = cvAcc >= desiredPerf(idx);
                        minIdx = find(hasDesiredPerf,1,'first');
                        if isempty(minIdx)
                            minIdx = length(cvAcc);
                        end
                        measureResults.learnerStats.terminatedPerf(idx) = preTransferValTest(minIdx);
                        measureResults.learnerStats.numIterations(idx) = minIdx -1;
                    end
                    
                end                
                if ~isempty(preTransferMeasures)
                    measureResults.learnerStats.preTransferMeasures = preTransferMeasures;
                    measureResults.learnerStats.preTransferMeasurePerfDiff = ...
                        abs(preTransferMeasures - preTransferValTest);
                end
                if ~isempty(transferMeasures)                    
                    measureResults.learnerStats.transferMeasures = transferMeasures;
                    measureResults.learnerStats.transferMeasurePerfDiff = ...
                        abs(transferMeasures - valTest);                    
                end
                if ~isempty(transferMeasures) && ~isempty(preTransferMeasures)
                    transferMeasureDifference = transferMeasures - preTransferMeasures;
                    measureResults.learnerStats.transferMeasureDifference = transferMeasureDifference;
                    measureResults.learnerStats.accuracyMeasureDifference =  ...
                        abs(measureResults.learnerStats.transferMeasureDifference - ...
                        transferDifference);
                    measureResults.learnerStats.negativeTransferPrediction = ...
                        (transferDifference >= 0) == ...
                        (transferMeasureDifference >= 0);
                    %{
                    measureResults.learnerStats.weightedPrecisionTransferLoss = ...
                        (1 - measureResults.learnerStats.negativeTransferPrediction) .* ...
                        abs(transferDifference);                        
                        %}
                    a = measureResults.learnerStats.negativeTransferPrediction;
                    b = preTransferValTest;
                    c = valTest;
                    d = transferMeasureDifference > 0;
                    %{
                    measureResults.learnerStats.weightedPrecisionTransferLoss = ...
                        (1-a) .* abs(transferDifference);
                    %}
                    measureResults.learnerStats.weightedPrecisionTransferLoss = ...
                        d.*c + (1-d).*b;
                end
            else
                if ~isempty(split.ID2Labels)
                    measureResults.ID2Labels = split.ID2Labels;                
                end
                measureResults.learnerStats = split.learnerStats;   
                if ~isempty(split.isNoisy)
                    isNoisyWeight = split.instanceWeights(split.isNoisy);
                    isNoisyAcc = mean(1-isNoisyWeight);
                    measureResults.learnerStats.isNoisyAcc = isNoisyAcc;
                end
                valTrain = sum(split.trainPredicted==split.trainActual)/...
                    numel(split.trainPredicted); 
                valTest = sum(split.testPredicted==split.testActual)/...
                    numel(split.testPredicted);                
                assert(all(split.testActual > 0));                
                numLabels = max(split.testActual);
                measureResults.trainPerfPerLabel = ResultsVector(zeros(numLabels,1));
                measureResults.testPerfPerLabel = ResultsVector(zeros(numLabels,1));
                for i=1:numLabels
                    measureResults.trainPerfPerLabel(i) = ...
                        Helpers.getLabelAccuracy(split.trainPredicted,...
                        split.trainActual,i);
                    measureResults.testPerfPerLabel(i) = ...
                        Helpers.getLabelAccuracy(split.testPredicted,...
                        split.testActual,i);
                end
            end
            if exist('valTest','var')
                measureResults.learnerStats.testResults = valTest;
            end
            if exist('valTrain','var')
                measureResults.learnerStats.trainResults = valTrain;
            end
        end
        
        function [aggregatedResults] = aggregateResults(obj,splitMeasures)
            aggregatedResults = struct();
            aggregatedResults.testResults = [];
            aggregatedResults.trainResults = [];
            aggregatedResults.trainLabelMeasures = [];
            aggregatedResults.testLabelMeasures = [];
            if isempty(splitMeasures)
                return;
            end
            sm1 = splitMeasures{1};
            if isfield(sm1,'ID2Labels')
                aggregatedResults.ID2Labels = sm1.ID2Labels;
                %aggregatedResults.dataSetWeights = sm1.dataSetWeights;
            end
            
            if numel(splitMeasures) > 0
                learnerStatFields = fields(sm1.learnerStats);
                learnerStats = Helpers.getValuesOfField(splitMeasures,'learnerStats');
                for i=1:length(learnerStatFields)
                    f = learnerStatFields{i};
                    if ~isempty(sm1.learnerStats.(f))
                        %measureResults.(f) = split.(f);
                        r = Helpers.getValuesOfField(learnerStats,f);
                        aggregatedResults.(f) = ResultsVector(r);
                    end                
                end
                
                if isfield(sm1.learnerStats,'featureTestAccs')
                    testAccs = Helpers.getValuesOfField(learnerStats,'featureTestAccs');
                    trainAccs = Helpers.getValuesOfField(learnerStats,'featureTrainAccs');
                    accsBest = zeros(size(trainAccs,1),1);
                    for splitIdx=1:size(trainAccs,1)
                        bestInd = argmax(trainAccs(splitIdx,:));
                        accsBest(splitIdx) = testAccs(splitIdx,bestInd);
                    end                    
                    aggregatedResults.featureTestAccsBest = ResultsVector(accsBest);
                end
                if isfield(sm1,'isNoisyAcc')
                    isNoisyAccs = Helpers.getValuesOfField(splitMeasures,'isNoisyAcc');
                    aggregatedResults.isNoisyAccs = ResultsVector(isNoisyAccs);
                end
                l = Helpers.Cell2StructArray(splitMeasures);
                l = [l.learnerStats];
                l1 = l(1);
                if isfield(l1,'featureSmoothness') && ...
                        isfield(l1,'featureWeights')                    
                    s = Helpers.StructField2Mat(l,'featureSmoothness');
                    if any(isnan(s(:)))
                        s(isnan(s)) = max(s(:));
                    end                    
                    w = abs(Helpers.StructField2Mat(l,'featureWeights'));
                    w = Helpers.NormalizeRows(w);                    
                    sw = sum(s.*w,2);
                    aggregatedResults.weightedFeatureSmoothness = ResultsVector(sw);
                end
            end
        end                
        function [prefix] = getPrefix(obj)
            prefix = '0-1 loss';
        end
        function  [d] = getDirectory(obj)
            error('Not implemented');
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
    end
end

