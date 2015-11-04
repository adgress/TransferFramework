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
            trainLabeled = ~isnan(r.yTrain) & ~r.isValidation;
            trainAccVec = r.trainPredicted==r.trainActual;            
            trainAccVec = trainAccVec(trainLabeled);
            valTrain = mean(trainAccVec);
            valTest = sum(r.testPredicted==r.testActual)/...
                        numel(r.testPredicted);   
        end
        
        
        function [measureResults] = evaluate(obj,split)
            measureResults = struct();                        
            if ~isempty(split.ID2Labels)
                measureResults.ID2Labels = split.ID2Labels;
            end
            measureResults.learnerStats = split.learnerStats;
            if ~isempty(split.isNoisy)
                isNoisyWeight = split.instanceWeights(split.isNoisy);
                isNoisyAcc = mean(1-isNoisyWeight);
                if isnan(isNoisyAcc)
                    isNoisyAcc = 0;
                end
                measureResults.learnerStats.isNoisyAcc = isNoisyAcc;
            end
            valTrain = sum(split.trainPredicted==split.trainActual)/...
                numel(split.trainPredicted);
            valTest = sum(split.testPredicted==split.testActual)/...
                numel(split.testPredicted);
            assert(all(~isnan(split.testActual)));
            numLabels = max(split.testActual);
            if round(numLabels) ~= numLabels
                numLabels = 1;
            end
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
            %end
            if exist('valTest','var')
                measureResults.learnerStats.testResults = valTest;
                measureResults.learnerStats.valTest = valTest;
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

