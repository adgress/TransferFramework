classdef MultiMeasure < Saveable
    %MULTIMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = MultiMeasure(configs)            
            if ~exist('configs','var')
                configs = [];                
            end
            obj = obj@Saveable(configs);
        end
        
        function [allResults] = computeMeasure(obj,results)
            
            numResults = length(results.measureResults{1}.allResults);
            numSplits = length(results.measureResults{1}.allResults{1}.splitResults);
            allResults = ResultsContainer(numSplits,numResults);
            for allResultsIdx=1:numResults                
                splitMeasures = cell(numSplits,1);
                splitResults = splitMeasures;
                for splitIdx=1:numSplits
                    changeInPerf = zeros(size(results.measureResults));
                    measureVals = changeInPerf;
                    for resultsIdx=1:length(results.measureResults)
                        measureResults = results.measureResults{resultsIdx};
                        baselineResults = results.baselineResults{resultsIdx};
                        methodResults = results.methodResults{resultsIdx};                                        
                        
                        MR = measureResults.allResults{allResultsIdx};
                        BR = baselineResults.allResults{allResultsIdx};
                        MeR = methodResults.allResults{allResultsIdx};
                        
                        MRsplit = MR.splitResults{splitIdx}.postTransferResults;
                        BRsplit = BR.splitMeasures{splitIdx}.testPerformance;
                        MeRsplit = MeR.splitMeasures{splitIdx}.testPerformance;
                        changeInPerf(resultsIdx) = MeRsplit - BRsplit;
                        measureVals(resultsIdx) = MRsplit.measureVal;                        
                    end
                    s = struct();                    
                    [s.selectedDataSet, s.measure, ...
                        s.testPerformance] = obj.pickDataset(measureVals,changeInPerf);
                    s.trainPerformance = 0;
                    splitMeasures{splitIdx} = s;
                    
                    splitResults{splitIdx} = struct();
                    splitResults{splitIdx}.trainingDataMetadata = MR.splitResults{splitIdx}.trainingDataMetadata;
                end
                r = Results(numSplits);
                r.splitMeasures = splitMeasures;
                r.splitResults = splitResults;                
                r.experiment = results.methodResults{1}.allResults{allResultsIdx}.experiment;                
                allResults.allResults{allResultsIdx} = r;
            end
            measure = Measure();
            allResults.aggregateResults(measure)
        end
        
        function [ind,measureVal,score] = pickDataset(obj, measureVals, changesInPerf)
            [measureVal, ind] = max(measureVals);
            score = changesInPerf(ind) - min(changesInPerf);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'MM';
        end
        function [d] = getDirectory(obj)
            d = '';
            assert(false);
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
    end
    
end

