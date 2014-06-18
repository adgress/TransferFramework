classdef Measure < Saveable
    %MEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = Measure(configs)
            obj = obj@Saveable(configs);
        end
        function [measureResults] = evaluate(obj,split)
            measureResults = struct();
            %Hack for Transfer Experiment
            if size(split.trainActual,2) == 1
                
                valTrain = sum(split.trainPredicted==split.trainActual)/...
                    numel(split.trainPredicted); 
                valTest = sum(split.testPredicted==split.testActual)/...
                    numel(split.testPredicted);                
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
            else
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
            measureResults.testPerformance = valTest;
            measureResults.trainPerformance = valTrain;
        end
        
        function [aggregatedResults] = aggregateResults(obj,splitMeasures)
            aggregatedResults = struct();
            testMeasures = ...
                Helpers.getValuesOfField(splitMeasures,'testPerformance');
            trainMeasures = ...
                Helpers.getValuesOfField(splitMeasures,'trainPerformance');                        
            aggregatedResults.testResults = ResultsVector(testMeasures);
            aggregatedResults.trainResults = ResultsVector(trainMeasures);
            aggregatedResults.trainLabelMeasures = ...
                ResultsVector(Helpers.getValuesOfField(splitMeasures,'trainPerfPerLabel'));
            aggregatedResults.testLabelMeasures  = ...
                ResultsVector(Helpers.getValuesOfField(splitMeasures,'testPerfPerLabel'));
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

