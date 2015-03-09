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
            valTrain = sum(r.trainPredicted==r.trainActual)/...
                        numel(r.trainPredicted); 
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
                
                for resultIdx=1:length(iterationResults)
                    r = iterationResults{resultIdx};
                    [valTrain(resultIdx),valTest(resultIdx)] = ...
                        obj.computeTrainTestResults(r);
                    if ~isempty(split.preTransferResults)
                        r2 = split.preTransferResults{resultIdx};
                        [preTransferValTrain(resultIdx), ...
                            preTransferValTest(resultIdx)] = ...
                            obj.computeTrainTestResults(r2);                        
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
                transferDifference = ...
                    valTest - preTransferValTest;                
                measureResults.learnerStats.preTransferValTrain = preTransferValTrain; 
                measureResults.learnerStats.preTransferValTest = preTransferValTest;
                measureResults.learnerStats.transferDifference = transferDifference;
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
                    measureResults.learnerStats.weightedPrecisionTransferLoss = ...
                        (1 - measureResults.learnerStats.negativeTransferPrediction) .* ...
                        abs(transferDifference);                        
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
                
                if isfield(sm1,'isNoisyAcc')
                    isNoisyAccs = Helpers.getValuesOfField(splitMeasures,'isNoisyAcc');
                    aggregatedResults.isNoisyAccs = ResultsVector(isNoisyAccs);
                end
                l = Helpers.Cell2StructArray(splitMeasures);
                l = [l.learnerStats];
                l1 = l(1);
                if isfield(l1,'weightedNegativeTransferLoss')
                    %v = [l.weightedNegativeTransferLoss];
                    v = Helpers.StructField2Mat(l,'weightedPrecisionTransferLoss');
                    isNonzero = v > 0;
                    a = sum(v)./sum(isNonzero);
                    a(isnan(a)) = 0;
                    aggregatedResults.weightedPrecisionTransferLoss = ResultsVector(a);
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

