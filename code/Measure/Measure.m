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
                %Hack for Transfer Experiment
                if size(split.trainActual,2) == 1

                    valTrain = sum(split.trainPredicted==split.trainActual)/...
                        numel(split.trainPredicted); 
                    valTest = sum(split.testPredicted==split.testActual)/...
                        numel(split.testPredicted);                
                    assert(all(split.testActual > 0));                
                    %{
                    %display('Using soft loss for measure!');
                    testVals = Helpers.SelectFromRows(split.testFU,split.testActual);
                    valTest = mean(testVals);
                    trainVals = Helpers.SelectFromRows(split.trainFU,split.trainActual);
                    valTrain = mean(trainVals);
                    %}
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
                elseif ~isempty(split.testPredicted)
                    trainPredicted = split.trainPredicted;
                    testPredicted = split.testPredicted;
                    if isKey(obj.configs,'k')
                        trainPredicted = trainPredicted(:,1:obj.configs('k'));
                        testPredicted = testPredicted(:,1:obj.configs('k'));
                    end
                    trainPredictedMat = logical(Helpers.createLabelMatrix(trainPredicted));
                    t = split.trainActual(:,1:size(trainPredictedMat,2));
                    trainIsCorrect = t(trainPredictedMat);
                    %valTrain = sum(trainIsCorrect(:))/numel(trainPredicted);
                    valTrain = -1;

                    testPredictedMat = logical(Helpers.createLabelMatrix(testPredicted));
                    n = size(testPredictedMat,1);
                    m = size(split.testActual,2) - size(testPredictedMat,2);
                    testPredictedMat = logical([testPredictedMat zeros(n,m)]);
                    testIsCorrect = split.testActual(testPredictedMat);

                    numCorrect = sum(testIsCorrect(:));
                    total = sum(testPredictedMat(:) | split.testActual(:));
                    useAcc = 1;
                    useInt = 0;
                    usePrec = 0;
                    useF1 = 0;
                    useMAP = 0;
                    if useAcc
                        valTest = sum(testIsCorrect(:))/length(testIsCorrect);
                        error('');
                    elseif useInt
                        valTest = numCorrect/total;
                    elseif usePrec
                        %valTest = sum(testIsCorrect(:))/numel(testIsCorrect);
                        scores = zeros(size(testPredicted,2),1);
                        for i=1:size(testPredicted,1)
                            pred = testPredicted(i,:);
                            actual = split.testActual(i,:);
                            numTags = sum(actual);   
                            score = 0;
                            for j=1:numTags
                                score = score + actual(pred(j));
                            end                        
                            scores(i) = score/numTags;
                        end
                        valTest = mean(scores);
                    elseif useF1
                        testActual = logical(split.testActual);
                        TP = testPredictedMat & testActual;
                        TN = ~testPredictedMat & ~testActual;
                        FP = testPredictedMat & ~testActual;
                        FN = ~testPredictedMat & testActual;
                        numTP = sum(TP(:));
                        numTN = sum(TN(:));
                        numFP = sum(FP(:));
                        numFN = sum(FN(:));
                        numP = numTP+numFP;
                        numN = numTN+numFN;
                        P = numTP/numP;
                        R = numTP/(numTP + numFN);
                        beta = 1;
                        valTest = (beta^2+1)*P*R/(beta^2*P+R);
                    elseif useMAP
                        scores = zeros(size(testPredicted,2),1);
                        for i=1:size(testPredicted,1)
                            pred = testPredicted(i,:);
                            actual = split.testActual(i,:);
                            numTags = sum(actual);                                                
                            score = actual(pred(1));
                            maxScore = 1;                        
                            for j=2:numTags
                                score = score + actual(pred(j))/log(j+1);
                                maxScore = maxScore + 1/log(j+1);
                            end                        
                            scores(i) = score/maxScore;
                        end
                        valTest = mean(scores);
                    else
                        assert(false);
                    end
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
                %{
                testMeasures = ...
                    Helpers.getValuesOfField(splitMeasures,'testPerformance');
                trainMeasures = ...
                    Helpers.getValuesOfField(splitMeasures,'trainPerformance');
                aggregatedResults.testResults = ResultsVector(testMeasures);
                aggregatedResults.trainResults = ResultsVector(trainMeasures);
                %}
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
                %{
                if isfield(sm1,'dataSetWeights');
                    weights = Helpers.getValuesOfField(splitMeasures,'dataSetWeights');
                    aggregatedResults.dataSetWeights = ResultsVector(weights);
                end
                %}
                if isfield(sm1,'isNoisyAcc')
                    isNoisyAccs = Helpers.getValuesOfField(splitMeasures,'isNoisyAcc');
                    aggregatedResults.isNoisyAccs = ResultsVector(isNoisyAccs);
                end
                %{
                aggregatedResults.trainLabelMeasures = ...
                    ResultsVector(Helpers.getValuesOfField(splitMeasures,'trainPerfPerLabel'));
                aggregatedResults.testLabelMeasures  = ...
                    ResultsVector(Helpers.getValuesOfField(splitMeasures,'testPerfPerLabel'));
                %}
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

