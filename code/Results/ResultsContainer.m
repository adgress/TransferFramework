classdef ResultsContainer < handle
    %RESULTSCONTAINER Summary of this class goes here
    %   Detailed explanation goes here

    properties
        numSplits
        allResults        
        mainConfigs
    end

    methods
        function obj = ResultsContainer(numSplits,numExperiments)
            obj.numSplits = numSplits;
            obj.allResults = cell(numExperiments,1);
            for i=1:numExperiments
                obj.allResults{i} = Results(obj.numSplits);
            end
        end        
        
        function [] = computeLossFunction(obj,measure)
            for i=1:numel(obj.allResults)
                if numel(obj.allResults{i}.experiment.learner) > 0
                    obj.allResults{i}.computeLossFunction(measure);
                end
            end
        end
        function [] = aggregateResults(obj,measure)
            for i=1:numel(obj.allResults)
                obj.allResults{i}.aggregateResults(measure);
            end
        end
        function [] = aggregateMeasureResults(obj,measureLoss)
            for i=1:numel(obj.allResults)
                obj.allResults{i}.aggregateMeasureResults(measureLoss);
            end
        end
        function [] = saveResults(obj,filename)
            if ProjectConfigs.smallResultsFiles
                for idx=1:length(obj.allResults)
                    for splitIdx=1:length(obj.allResults{idx})
                        r = obj.allResults{idx}.splitResults{splitIdx};
                        r.shrink();
                    end
                end
            end
            c = obj.mainConfigs;
            obj.mainConfigs = [];
            results = obj;
            warning off;
            [~] = mkdir(fileparts(filename));
            warning on;
            save(filename,'results');
            obj.mainConfigs = c;
        end
        function [results] = getResultsForMethod(obj,learnerClass,resultsQuery)
            results = {};
            for i=1:numel(obj.allResults)
                experiment = obj.allResults{i}.experiment;
                learner = experiment.learner;
                shouldAdd = isequal(learnerClass,class(learner)) || ...
                        (isempty(learnerClass) && isempty(learner));
                shouldAdd = shouldAdd && Helpers.structMatchesQuery(experiment, resultsQuery);
                if shouldAdd
                    results{end+1} = obj.allResults{i};
                end
            end                        
        end
    end

    methods(Access=protected)
        function [experiments] = getResultsMatchingQuery(obj,query)
            queryKeys = query.keys;
            experiments = {};
            for i=1:numel(obj.allExperiments)                
                isMatch = true;            
                input = obj.allExperiments{i};
                for j = 1:length(queryKeys)
                    key = queryKeys{j};
                    if ~input.isKey(key)
                        error('Cannot find query key in results.input: %s',key);
                    end
                    queryValues = query(key);
                    inputValue = input.(key);
                    valueFound = false;
                    for k=1:length(queryValues)
                        queryValue = queryValues{k};
                        if isa(inputValue,'char')
                            if strcmp(inputValue,queryValue)
                                valueFound = true;
                                break;
                            end
                        else
                            if inputValue == queryValue
                                valueFound = true;
                                break;
                            end
                        end
                    end
                    if ~valueFound
                        isMatch = false;
                        break;
                    end
                end
                if isMatch
                    %fprintf('Adding: %s\n',files(i).name);
                    allResults{end+1} = input;
                end
            end
        end        
    end
   
    
end

