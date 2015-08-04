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
            cv = CrossValidation();
            cv.trainData = input.train.copy();
            cv.parameters = obj.get('cvParameters');
            cv.methodObj = obj;
            cv.measure = obj.get('measure');
            [bestParams,acc] = cv.runCV();
            obj.setParams(bestParams);
            [testResults,savedData] = obj.runMethod(input);
            if ~obj.configs.get('quiet')
                display([obj.getPrefix() ' Acc: ' num2str(savedData.val)]);
            end
        end
        
        function [testResults,savedData] = runMethod(obj,input,savedData)
            testResults = FoldResults();
            train = input.train;
            test = input.test;
            
            %combined = DataSet.Combine(train,test);
            combined = train;
            f = obj.configs.get('combineGraphFunc',[]);
            if ~isempty(f)
                combined = f(combined);
            end
            distMat = DistanceMatrix(combined.W,combined.Y,combined.type,...
                combined.trueY,combined.instanceIDs);
            origW = distMat.W;
            
            %distMat.W = Helpers.SimilarityToDistance(distMat.W);
            %distMat.W = Helpers.distance2RBF(distMat.W,obj.get('sigma'));            

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
            WStudCorrect = origW(isStudent,isTestCorrect);
                                    
            predictedSkills = obj.getPrediction(size(WStudCorrect,1),...
                size(WStudCorrect,2));
            if isequal(class(obj),'ITSMethod')
                %display('Hack - fix this');
                numLabels = length(unique(distMat.labelSets));
                studentSkills = zeros(sum(isStudent),numLabels);
                YTrain = distMat.Y(isTrainCorrect); 
                for labelIdx=1:numLabels
                    WwithLabel = WStudCorrectTrain(:,YTrain == labelIdx);
                    studentSkills(:,labelIdx) = mean(WwithLabel,2);
                    %studentSkills(:,labelIdx) = a ./ (a + m);
                end
                
                studentSkills(isnan(studentSkills)) = .5;
                studentSkills(isinf(studentSkills)) = .5;
                I = sum(studentSkills,2) == 0;
                studentSkills(I,:) = .5;
                %studentSkills = Helpers.NormalizeRows(studentSkills);
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
            
            testResults.learnerMetadata.cvAcc = [];
            savedData.val = val;
        end
        
        function [v] = getPrediction(obj,numRows,numCols)
            v = rand(numRows,numCols);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'ITSMethod';
        end
    end
    
end

