classdef CrossValidation < handle
    %CROSSVALIDATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        parameters
        methodObj
        trainData
        splits
        measure
    end
    
    methods
        function obj = CrossValidation()         
        end
        
        function [] = createCVSplits(obj,numSplits,percTrain)
            percArray = [percTrain 1-percTrain 0];
            Y = obj.trainData.Y;
            Y(obj.trainData.isTargetTest()) = -1;
            obj.splits = cell(numSplits,1);
            for idx=1:numSplits
                obj.splits{idx} = LabeledData.generateSplit(...
                    percArray,Y,Configs());
            end
        end
        
        function [bestParams, bestAcc] = runCV(obj)
            if isempty(obj.splits)
                obj.createCVSplits(10,.8);
            end
            if isempty(obj.measure)
                obj.measure = Measure();
            end
            obj.trainData.removeTestLabels();
            obj.trainData.setTargetTrain();
            paramPowerSet = obj.makeParamPowerSet(obj.parameters);
            if isempty(paramPowerSet)
                paramPowerSet{1} = [];
            end
            paramResults = cell(size(paramPowerSet));
            processedResults = cell(size(paramPowerSet));
            accs = zeros(size(paramPowerSet));
            trainAccs = accs;
            for paramIdx=1:length(paramPowerSet)
                splitResults = cell(size(obj.splits));
                processedSplitResults = cell(size(obj.splits));
                params = paramPowerSet{paramIdx};
                obj.methodObj.setParams(params);
                acc = 0;
                trainAcc = 0;
                savedData = struct();
                for splitIdx=1:length(obj.splits)
                    input = struct();
                    s = obj.splits{splitIdx};
                    [train,test,~] = obj.trainData.splitDataSet(s);
                    ns = obj.trainData.type ~= Constants.SOURCE;                    
                    train.type(s == 1 & ns) = Constants.TARGET_TRAIN;
                    train.type(s == 2 & ns) = Constants.TARGET_TEST;
                    test.type(s == 1 & ns) = Constants.TARGET_TRAIN;
                    test.type(s == 2 & ns) = Constants.TARGET_TEST;
                    input.train = train;
                    input.test = test;
                    [splitResults{splitIdx},savedData] = ...
                        obj.methodObj.runMethod(input,savedData);
                    processedSplitResults{splitIdx} = ...
                        obj.measure.evaluate(splitResults{splitIdx});
                    acc = acc + processedSplitResults{splitIdx}.learnerStats.testResults;
                    trainAcc = acc + processedSplitResults{splitIdx}.learnerStats.trainResults;
                end
                accs(paramIdx) = acc/length(obj.splits);
                trainAccs(paramIdx) = trainAcc/length(obj.splits);
                paramResults{paramIdx} = splitResults;
            end
            [~,bestInd] = max(accs);
            bestParams = paramPowerSet{bestInd};
            bestAcc = accs(bestInd);
            bestAcc
        end
        
        % {a, {a1,a2,...,an}}
        function [retVal] = makeParamPowerSet(obj,params)
            if isempty(params)
                retVal = {};
                return;
            end
            keys = {params.key};
            values = {params.values};
            inds = cell(length(params),1);
            for idx=1:length(params)
                inds{idx} = 1:length(values{idx});
            end
            v = Helpers.combvec(inds{:});
            p = cell(size(v));
            for idx=1:length(v)
                p{idx} = Helpers.selectFromCellofCells(values,v{idx});
            end
            retVal = cell(size(p));
            for idx=1:length(p)
                a = struct('key',keys,'value',p{idx});
                retVal{idx} = a;
            end
        end
    end
    
end

