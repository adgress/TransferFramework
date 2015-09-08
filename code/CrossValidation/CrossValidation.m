classdef CrossValidation < Saveable
    %CROSSVALIDATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        parameters
        methodObj
        trainData
        splits
        measure
        print
    end
    
    methods
        function obj = CrossValidation()         
            obj = obj@Saveable();
            obj.set('print',false);
        end
        
        function [] = setData(obj,X,Y)
            obj.trainData = DataSet([],[],[],X,Y);
        end
        
        function [] = createCVSplits(obj,numSplits,percTrain)
            percArray = [percTrain 1-percTrain 0];
            Y = obj.trainData.Y;
            Y(obj.trainData.isTargetTest()) = nan;
            obj.splits = cell(numSplits,1);
            c = Configs();
            if obj.trainData.isRegressionData
                c.set('regProb',true);
            end
            for idx=1:numSplits
                obj.splits{idx} = LabeledData.generateSplit(...
                    percArray,Y,c);
            end
        end
        
        function [bestParams, bestAcc] = runCV(obj)
            if isempty(obj.splits)
                obj.createCVSplits(10,.8);
            end
            for idx=1:length(obj.splits)
                I = obj.splits{idx} == 0;
                obj.splits{idx}(I) = 1;
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
                    
                    %Is this necessary?
                    if ~isempty(train.W)
                        train.type(s == 1 & ns) = Constants.TARGET_TRAIN;
                        train.type(s == 2 & ns) = Constants.TARGET_TEST;
                        test.type(s == 1 & ns) = Constants.TARGET_TRAIN;
                        test.type(s == 2 & ns) = Constants.TARGET_TEST;
                    end
                    input.train = train;
                    input.test = test;
                    %Don't use cached data until ordering issues are
                    %figured out
                    %{
                    [splitResults{splitIdx},savedData] = ...
                        obj.methodObj.runMethod(input,savedData);
                    %}
                    
                    
                    [splitResults{splitIdx}] = ...
                        obj.methodObj.runMethod(input);
                    processedSplitResults{splitIdx} = ...
                        obj.measure.evaluate(splitResults{splitIdx});
                    acc = acc + processedSplitResults{splitIdx}.learnerStats.testResults;
                    trainAcc = acc + processedSplitResults{splitIdx}.learnerStats.trainResults;
                end
                accs(paramIdx) = acc/length(obj.splits);
                trainAccs(paramIdx) = trainAcc/length(obj.splits);
                paramResults{paramIdx} = splitResults;
            end
            print = 0;
            if print
                for idx=1:length(paramPowerSet)                    
                    p = paramPowerSet{idx};
                    for sIdx=1:length(p);
                        s = p(sIdx).value;
                        if isa(s,'double')
                            s = num2str(s);
                        end
                        display([p(sIdx).key ': ' s]);
                    end
                    display(num2str(accs(idx)));
                end
            end
            I = Helpers.isInfOrNan(accs);
            assert(~any(I));
            [~,bestInd] = max(accs);
            bestParams = paramPowerSet{bestInd};
            bestAcc = accs(bestInd);
            if obj.get('print')
                display(['Best Acc:' num2str(bestAcc)]);
                for idx=1:length(bestParams)
                    display([bestParams(idx).key ': ' num2str(bestParams(idx).value)]);
                end
            end
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

