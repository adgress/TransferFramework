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
    files = [options.fileNames options.measureFiles];
    for i=1:numel(files)
        fileName = files{i};
        fileName = ['results/' options.dataSet '/' fileName];
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
    numColors = numColors*numel(results.configs('methodClasses'));
    numColors = numColors + numel(options.measureFiles);
    colors = colormap(hsv(numColors));
    index = 1;    
    maxSize = 15;
    for i=1:numel(files)
        fileName = files{i};
        fileName = ['results/' options.dataSet '/' fileName];
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
            if isKey(allResults.configs,'transferMethodClass')
                transferClass = str2func(allResults.configs('transferMethodClass'));
                transferObject = transferClass();
                transferName = transferObject.getDisplayName(configs);
                learnerName = [learnerName ';' transferName];
            elseif isKey(allResults.configs,'preTransferMeasure')
                error('Not implemented yet');
                measure = allResults.configs('preTransferMeasure');
                measureName = TransferMeasure.getDisplayName(measure,configs);
                learnerName = measureName;
            end        

            sizes = getSizes(results,options.xAxisField);

            if options.showRelativePerformance && isKey(configs,'postTransferMeasures')
                measures = configs('postTransferMeasures');
                for i=1:numel(measures)
                    if ~isKey(options.measuresToShow,measures{i})
                        continue;
                    end
                    dispName = TransferMeasure.GetDisplayName(measures{i},configs);
                    [m,v,l,u] = getRelativePerf(results,'PTMResults',...
                        'testResults',i,options);
                    if ~isempty(v)
                        if sum(isinf(m)) > 0
                            display('NaN');
                        end
                        errorbar(sizes,m,v,'color',colors(index,:));
                    else                    
                        errorbar(sizes,m,l,u,'color',colors(index,:));
                    end
                    leg{index} = [learnerName ':' dispName];
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
                end                

                
                
                if options.showTrain
                    vars = getVariances(results,'trainResults');
                    means = getMeans(results,'trainResults');
                    errorbar(sizes,means,vars,'color',colors(index,:));
                    leg{index} = [learnerName ', Train'];
                    index = index+1;
                end      
                if options.showPostTransferMeasures && isKey(configs,'postTransferMeasures')
                    [leg,index] = plotMeasureResults(options,configs,results,sizes,...
                        'postTransferMeasures','PostTMResults','PostTM',...
                        learnerName,leg,index,colors);
                end
                if options.showPreTransferMeasures && isKey(configs,'preTransferMeasures')
                    [leg,index] = plotMeasureResults(options,configs,results,sizes,...
                        'preTransferMeasures','PreTMResults','PreTM',...
                        learnerName,leg,index,colors);
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
        x = results{i}.aggregatedResults.(field1){index};
        y = results{i}.aggregatedResults.(field2);
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