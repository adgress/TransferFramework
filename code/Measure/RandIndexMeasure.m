classdef RandIndexMeasure < Measure
    %RANDINDEXMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = RandIndexMeasure(configs)
            obj = obj@Measure(configs);
        end
        function [measureResults] = evaluate(obj,split)
            measureResults = struct();            
            measureResults.trainPerformance = obj.getPerformance(split.trainResults);
            measureResults.testPerformance = obj.getPerformance(split.testResults);
            %{
            trainCo = obj.createCooccurenceMatrix(idxTrain1,idxTrain2);
            trainIsTP = trainCo & trainIsPositive;
            trainIsFP = trainCo & ~trainIsPositive;
            %}
            
            %{
            testCo = obj.createCooccurenceMatrix(idxTest1,idxTest2);
            %}
            
        end
        
        function [aggregatedResults] = aggregateResults(obj,splitMeasures)
            aggregatedResults = struct();
            testMeasures = ...
                Helpers.getValuesOfField(splitMeasures,'testPerformance');
            trainMeasures = ...
                Helpers.getValuesOfField(splitMeasures,'trainPerformance');                        
            aggregatedResults.testResults = ResultsVector(testMeasures);
            aggregatedResults.trainResults = ResultsVector(trainMeasures);
        end   
        
        function [val] = getPerformance(obj,results)
            %{
            setsToUse = obj.configs('setsToUse');
            trainIndex = obj.configs('trainSetIndex');
            testIndex = obj.configs('testSetIndex');
             %}          
            idx1 = results.idxPerDataset{1};
            idx2 = results.idxPerDataset{2};
            coMatrix12 = obj.createCooccurenceMatrix(idx1,idx2);
            coMatrix11 = obj.createCooccurenceMatrix(idx1,idx1);
            coMatrix22 = obj.createCooccurenceMatrix(idx2,idx2);
            %coMatrix = coMatrix12;
            coMatrix = [coMatrix11 coMatrix12; coMatrix12' coMatrix22];
            
            z11 = zeros(length(idx1));
            z22 = zeros(length(idx2));
            Y = results.W > 0;
            Y = [z11 Y; Y' z22];
            
            TP = Y & coMatrix; 
            TN = ~Y & ~coMatrix;
            FN = Y & ~coMatrix;
            FP = ~Y & coMatrix;
            numTP = sum(TP(:));
            numTN = sum(TN(:));
            numFP = sum(FP(:));
            numFN = sum(FN(:));
            numP = numTP+numFP;
            numN = numTN+numFN;
            P = numTP/numP;
            R = numTP/(numTP + numFN);
            beta = 2;
            
            %F1 Score
            %val = (beta^2+1)*P*R/(beta^2*P+R);
            
            %Rand Index
            numAll = numel(Y);
            val = (numTP+numTN) / numAll;
            
            %Precision
            %val = P;
            if isnan(val)
                val = 0;
            end
            if val == 1
                display('');
            end
        end
        
        function [W] = createCooccurenceMatrix(obj,ind1,ind2)
            W = zeros(length(ind1),length(ind2));
            maxInd = max([ind1;ind2]);
            for i=1:maxInd
                v1 = (ind1==i)+0;
                v2 = (ind2==i)+0;
                W = W + v1*v2';
            end
        end
        
                     
        function [prefix] = getPrefix(obj)
            prefix = 'RI';
        end
        function  [d] = getDirectory(obj)
            error('Not implemented');
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
    end
    
end

