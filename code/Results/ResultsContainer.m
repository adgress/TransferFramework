classdef ResultsContainer < handle
    %RESULTSCONTAINER Summary of this class goes here
    %   Detailed explanation goes here

    properties
        numSplits
        allResults        
        configs
    end

    methods
        function obj = ResultsContainer(numSplits,allExperiments)
            obj.numSplits = numSplits;
            numExperiments = numel(allExperiments);
            obj.allResults = cell(numExperiments,1);
            for i=1:numExperiments
                obj.allResults{i} = Results(obj.numSplits);
            end
        end        
        
        function [] = processResults(obj,measure)
            for i=1:numel(obj.allResults)
                obj.allResults{i}.processResults(measure);
            end
        end
        function [] = aggregateResults(obj,measure)
            for i=1:numel(obj.allResults)
                obj.allResults{i}.aggregateResults(measure);
            end
        end
        function [] = aggregateMeasureResults(obj)
            for i=1:numel(obj.allResults)
                obj.allResults{i}.aggregateMeasureResults();
            end
        end
        function [] = saveResults(obj,filename)
            results = obj;
            save(filename,'results');
        end
        function [results] = getResultsForMethod(obj,methodClass)
            results = {};
            for i=1:numel(obj.allResults)
                if isequal(methodClass,obj.allResults{i}.experiment.methodClass)
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

