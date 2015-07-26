classdef ITSMethod < Method
    %ITSMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ITSMethod(configs)            
            obj = obj@Method(configs);
        end
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            testResults = FoldResults();
            train = input.train;
            test = input.test;
            
            combined = DataSet.Combine(train,test);
            f = obj.configs.get('combineGraphFunc');
            combined = f(combined);
            distMat = DistanceMatrix(combined.W,combined.Y,combined.type,...
                combined.trueY,combined.instanceIDs);
            distMat.WNames = combined.WNames;
            distMat.WIDs = combined.WIDs;
            distMat.labelSets = combined.labelSets;
            distMat.objectType = combined.objectType;
            distMat.YNames = combined.YNames;
            
            isStudent = distMat.objectType == Constants.STUDENT;
            isTestCorrect = distMat.objectType == Constants.STEP_CORRECT & ...
                distMat.isTargetTest;
            isTrainCorrect = distMat.objectType == Constants.STEP_CORRECT & ...
                distMat.isTargetTrain & distMat.isLabeled;
            
            WStudCorrectTrain = distMat.W(isStudent,isTrainCorrect);            
            WStudCorrect = distMat.W(isStudent,isTestCorrect);
                                    
            predictedSkills = obj.getPrediction(size(WStudCorrect,1),...
                size(WStudCorrect,2));
            if isequal(class(obj),'ITSMethod')
                display('Hack - fix this');
                numLabels = length(unique(distMat.labelSets));
                studentSkills = zeros(sum(isStudent),numLabels);
                YTrain = distMat.Y(isTrainCorrect);
                for labelIdx=1:numLabels
                    WwithLabel = WStudCorrectTrain(:,YTrain == labelIdx);
                    studentSkills(:,labelIdx) = mean(WwithLabel,2);
                end
                YTest = distMat.Y(isTestCorrect);
                predictedSkills(:) = 0;
                for testIdx=1:size(predictedSkills,2)
                    currY = YTest(testIdx);
                    predictedSkills(:,testIdx) = studentSkills(:,currY);
                end
            end
            actualSkills = WStudCorrect;
            
            testResults.labelSets = distMat.labelSets;
            testResults.yPred = predictedSkills;
            testResults.yActual = actualSkills;
            %{
            testResults.dataType = distMat.type;
            testResults.dataFU = sparse(fu);
            testResults.labelSets = distMat.labelSets;
            testResults.yPred = yPred;
            testResults.yActual = yActual;
            %}
            error = abs(predictedSkills - actualSkills);
            normalizedError = sum(error(:)) / numel(actualSkills);
            val = 1 - normalizedError;
            display([obj.getPrefix() ': ' num2str(val)]);
        end
        function [v] = getPrediction(obj,numRows,numCols)
            v = rand(numRows,numCols);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'ITSMethod';
        end
    end
    
end

