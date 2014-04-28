function [f] = visualizeResults(options,f)
    if nargin < 1
        f = figure;
    end
    hold on;
    leg = {};
    %symbols = {'.','+','v','x'};
    numColors = numel(options.fileNames);
    if options.showTrain
        numColors = 2*numColors;
    end
    baselineFiles = {};    
    files = [options.baselineFiles options.fileNames];    
    for i=1:numel(files)
        fileName = ['results/' options.prefix '/' options.dataSet '/' files{i}];
        results = load(fileName);
        results = results.results;
        configs = results.configs;
        if (options.showRelativePerformance || options.showPostTransferMeasures) ...
                && isKey(configs,'postTransferMeasures')
            measures = configs('postTransferMeasures');
            for j=1:numel(measures)
                if isKey(options.measuresToShow,measures{j})
                    numColors = numColors+1;
                end
            end
            
        end
    end
    numColors = 5;
    if options.showRelativePerformance
        numBaselineFiles = numel(options.baselineFiles);
        assert(numBaselineFiles > 0);
        baselineFiles = files(1:numBaselineFiles);
        files = files(numBaselineFiles+1:end);
    end
    numColors = numColors*numel(results.configs('methodClasses'));
    colors = colormap(hsv(numColors));
    index = 1;    
    for i=1:numel(files)
        fileName = ['results/' options.prefix '/' options.dataSet '/' files{i}];
        allResults = load(fileName);
        allResults = allResults.results;
        
        %configs = results.allResults{1}.experiment;
        configs = allResults.configs;
        methodClasses = allResults.configs('methodClasses');
        for j=1:numel(methodClasses)
            methodClassString = methodClasses{j};            
            if ~isKey(options.methodsToShow,methodClassString)
                continue;
            end
            [results] = allResults.getResultsForMethod(methodClassString);
            learnerName = eval([methodClassString '.getMethodName(configs);']);
            hasPostTM = isKey(configs,'postTransferMeasures') && ...
                ~isempty(configs('postTransferMeasures'));
            hasPreTM = isKey(configs,'preTransferMeasures') && ...
                ~isempty(configs('preTransferMeasures'));
            hasTestResults = isfield(results{1}.aggregatedResults,'testResults');
            if isKey(allResults.configs,'transferMethodClass')
                transferClass = str2func(allResults.configs('transferMethodClass'));
                transferObject = transferClass();
                transferName = transferObject.getDisplayName(configs);
                learnerName = [learnerName ';' transferName];
            elseif hasPreTM
                error('Not implemented yet');
                measure = allResults.configs('preTransferMeasure');
                measureName = TransferMeasure.getDisplayName(measure,configs);
                learnerName = measureName;
            end        

            sizes = getSizes(results,options.xAxisField);
            
            if options.showRelativePerformance && hasTestResults
                baselineFile = ['results/' options.prefix '/' options.dataSet '/' baselineFiles{1}];
                baselineResults = load(baselineFile);
                baselineResults = baselineResults.results.allResults;
                for k=1:numel(measures)
                    for i=1:numel(results)
                        results{i}.aggregatedResults.baseline = ...
                            baselineResults{i}.aggregatedResults.testResults;
                    end
                    field1 = 'baseline';
                    field2 = 'testResults';
                    [m,v,l,u] = getRelativePerf(results,field1,...
                        field2,k,options);
                    if ~isempty(v)
                        if sum(isinf(m)) > 0
                            display('NaN');
                        end
                        errorbar(sizes,m,v,'color',colors(index,:));
                    else                    
                        errorbar(sizes,m,l,u,'color',colors(index,:));
                    end
                    dispName = TransferMeasure.GetDisplayName(measures{k},configs);
                    %leg{index} = ['Relative' learnerName '/' dispName];
                    leg{index} = ['Relative Acc: ' learnerName];
                    index = index+1;
                end
            else
                if isfield(results{1}.aggregatedResults,'testResults')
                    vars = getVariances(results,'testResults',-1);
                    means = getMeans(results,'testResults',-1);
                    errorbar(sizes,means,vars,'color',colors(index,:));
                    if options.showTrain
                        learnerName = [learnerName ', Test'];
                    end
                    leg{index} = learnerName;
                    index = index+1;
                    if options.showTrain
                        vars = getVariances(results,'trainResults');
                        means = getMeans(results,'trainResults');
                        errorbar(sizes,means,vars,'color',colors(index,:));
                        leg{index} = [learnerName ', Train'];
                        index = index+1;
                    end 
                end                                                
                                     
                if hasPostTM && hasPreTM && options.showRelativeMeasures
                    %{
                    [leg,index] = plotMeasureResults(options,configs,results,sizes,...
                            'postTransferMeasures','PostTMResults','PostTM',...
                            learnerName,leg,index,colors);
                    %}
                    measureIndex = 1;
                    field2 = 'PostTMResults';
                    field1 = 'PreTMResults';
                    [means,vars,lows,ups] = getRelativePerf(results,...
                        field1,field2,measureIndex,options);                    
                    errorbar(sizes,means,vars,'color',colors(index,:));
                    measures = configs('postTransferMeasures');
                    dispName = TransferMeasure.GetDisplayName(measures{1},configs);
                    leg{index} = ['Relative Measure: ' dispName];
                    index = index + 1;
                else
                    if options.showPostTransferMeasures && hasPostTM
                        [leg,index] = plotMeasureResults(options,configs,results,sizes,...
                            'postTransferMeasures','PostTMResults','PostTM',...
                            learnerName,leg,index,colors);
                    end
                    if options.showPreTransferMeasures && hasPreTM
                        [leg,index] = plotMeasureResults(options,configs,results,sizes,...
                            'preTransferMeasures','PreTMResults','PreTM',...
                            learnerName,leg,index,colors);
                    end
                end
            end
        end
    end
    if options.showLegend
        legend(leg);
    end
    numTrain = results{1}.aggregatedResults.metadata.numTrain;
    numTest = results{1}.aggregatedResults.metadata.numTest;
    numSourceLabels = ...
        results{1}.aggregatedResults.metadata.numSourceLabels;
    xAxisLabel = [options.xAxisDisplay ' (Num Source Labels = ' ...
        num2str(numSourceLabels) ...
        ', ' num2str(numTrain) '/' num2str(numTest) ')'];
    xlabel(xAxisLabel,'FontSize',8);
    ylabel(options.yAxisDisplay,'FontSize',8);
    axisToUse = options.axisToUse;
    axis(axisToUse);
    hold off;    
end

function [leg,index] = plotMeasureResults(options,configs,results,sizes,field,...
    resultField,displayName,learnerName,leg,index,colors)
    measures = configs(field);
    for k=1:numel(measures)
        if ~isKey(options.measuresToShow,measures{k})
            continue;
        end
        dispName = TransferMeasure.GetDisplayName(measures{k},configs);
        
        tranferMeans = getMeans(results,resultField,k);
        tranferVars = getVariances(results,resultField,k);
        errorbar(sizes,tranferMeans,tranferVars,'color',colors(index,:));
        
        leg{index} = [displayName ':' learnerName ':' dispName];
        index = index+1;
    end
end

function [means,vars,lows,ups] = getRelativePerf(results,field1,field2,index,options)
    means = zeros(numel(results),1);
    vars = [];
    ups = [];
    lows = [];
    if options.relativeType == Constants.RELATIVE_PERFORMANCE
        vars = means;
    else
        ups = means;
        lows = means;
    end
    for i=1:numel(results);        
        x = results{i}.aggregatedResults.(field1);
        y = results{i}.aggregatedResults.(field2);
        if iscell(x)
            x = cell2mat(x);
        end
        if iscell(results{i}.aggregatedResults.(field2))
            y = cell2mat(y);
        end
        if size(x,1) ~= size(y,1)            
            y = y';
        end
        if options.relativeType == Constants.RELATIVE_PERFORMANCE
            relativePerf = ...
                ResultsVector.GetRelativePerformance(x,y);
            means(i) = relativePerf.getMean();
            vars(i) = relativePerf.getVar();        
        elseif options.relativeType == Constants.CORRELATION
            [means(i),ups(i),lows(i)] = ResultsVector.GetCorrelation(x,y);
        else
            error('Unknown Relative Type');
        end
    end
end

function [vars] = getVariances(results,name,index)
    vars = zeros(numel(results),1);
    for i=1:numel(results);
        if index < 0
            vars(i) = ...
                results{i}.aggregatedResults.(name).getVar();        
        else
            vars(i) = ...
                results{i}.aggregatedResults.(name){index}.getVar();
        end
    end
end

function [means] = getMeans(results,name,index)
    means = zeros(numel(results),1);
    for i=1:numel(results);
        if index < 0
            means(i) = ...
                results{i}.aggregatedResults.(name).getMean();
        else
            means(i) = ...
                results{i}.aggregatedResults.(name){index}.getMean();
        end
    end
end

function [sizes] = getSizes(results,sizeField)
    sizes = zeros(numel(results),1);
    for i=1:numel(results);
        sizes(i) = ...
            results{i}.aggregatedResults.metadata.(sizeField);
    end
end