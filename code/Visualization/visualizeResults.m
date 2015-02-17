function [f, returnStruct] = visualizeResults(options,f)
    if nargin < 1
        f = figure;
    end
    hold on;
    index = 1;   
    displayVals = {};
    allPlotConfigs = options.get('plotConfigs');
    numColors = length(allPlotConfigs);
    colors = colormap(hsv(numColors));
    for i=1:length(allPlotConfigs)
        plotConfigs = allPlotConfigs{i};                
        fileName = options.makeResultsFileName(plotConfigs.get('resultFileName'));
        if ~exist(fileName,'file')
            display([fileName ' doesn''t exist - skipping']);
            continue
        end
        allResults = load(fileName);
        allResults = allResults.results;
        configs = allResults.mainConfigs;

        learners = configs.get('learners');
        learnerClassString = '';
        if numel(learners) > 0
            learnerClassString = class(learners);
        end                    
        [results] = allResults.getResultsForMethod(learnerClassString,options.c.resultQueries);

        sizes = getSizes(results,options.c.sizeField);
        if options.has('sizeToUse')
            assert(~isempty(intersect(sizes,options.c.sizeToUse)));
            sizes = options.c.sizeToUse;
        end 
        fieldToPlot = 'testResults';
        if plotConfigs.has('fieldToPlot')
            fieldToPlot = plotConfigs.get('fieldToPlot');
        end
        [results] = getResultsWithSize(results,sizes);
        if options.has('vizBarChartForField') && ...
                options.c.vizBarChartForField
            displayVals{end+1} = plotField(results,...
                fieldToPlot,colors(index,:),options);
        else           
            displayVals{end+1} = plotResults(results,sizes,fieldToPlot,colors(index,:),options);
        end
        index = index + 1;
    end
        
    leg = options.get('legend');
    
    %Plot is empty
    if index == 1
        leg = {};
    end
    if options.c.showLegend && ~isempty(leg) && ~options.c.showTable
        legend(leg,'Location','southeast');
    end
    if options.c.showTable
        tableData = makeResultsTableData(displayVals);
        if isfield(options,'tableColumns') && ~isempty(options.c.tableColumns)
            assert(length(options.c.tableColumns) == length(leg));
            leg = options.c.tableColumns;
        end
        set(options.c.table,'Data',tableData,'ColumnName',leg,'RowName',options.c.dataSet);
    else
        if options.has('axisToUse') && ~options.c.vizMeasureCorrelation
            axisToUse = options.c.axisToUse;    
            a = axis;
            a(3:4) = axisToUse(3:4);
            axis(a);
        end
        xAxisLabel = '';
        if exist('results','var')      
            xAxisLabel = options.c.xAxisDisplay;            
        end    
        if options.get('showXAxisLabel')
            xlabel(xAxisLabel,'FontSize',8);
        end
        if options.get('showYAxisLabel')
            ylabel(options.c.yAxisDisplay,'FontSize',8);
        end
    end
    hold off;    
    returnStruct = struct();
    returnStruct.numItemsInLegend = length(leg);
    returnStruct.displayVals = displayVals;
    returnStruct.sizes = sizes;
end

function [c] = makeResultsTableData(resultStructs)
    c = {};
    precision = 2;
    for idx=1:length(resultStructs)
        r = resultStructs{idx};
        c{idx} = [num2str(r.means,precision) '+/-' num2str(r.vars,precision)];
    end
end

function [s] = makeResultsStruct(means,vars)
    s = struct();
    s.means = means;
    s.vars = vars;
end

function [displayVal] = plotRelativeMeasures(options,results,sizes,...
    hasPostTM,hasPreTM,color)
    assert(hasPostTM && hasPreTM && options.c.showRelativeMeasures);
    field2 = 'PostTMResults';
    field1 = 'PreTMResults';
    [means,vars,lows,ups] = getRelativePerf(results,...
        field1,field2,options);
    means(isnan(means)) = 0;
    means(isinf(means)) = 2;
    vars(isnan(vars)) = 0;
    means = mean(means,2);
    vars = mean(vars,2);
    if ~options.c.vizMeasureCorrelation
        errorbar(sizes,means,vars,'color',color);    
    end
    displayVal = makeResultsStruct(means,vars);
end

function [newResults] = getResultsWithSize(results,size)
    newResults = {};
    for i=1:length(results)
        r = results{i};
        if r.experiment.numLabeledPerClass == size
            newResults{end+1} = r;
        end
    end
end

function [displayVal] = plotField(results,field,color,options)
    assert(length(results) == 1);
    vars = getVariances(results,field,options);
    means = getMeans(results,field);    
    %errorbar(1:length(means),means,vars,'color',color);    
    %bar(1:length(means),means,vars,'color',color);    
    barwitherr(vars,means,'r');    
    displayVal = makeResultsStruct(means,vars);
end

function [displayVal] = plotResults(results,sizes,field,colors,options)        
    vars = getVariances(results,field,options);
    means = getMeans(results,field);
    if ~options.c.vizMeasureCorrelation
        if length(means) == length(sizes)
            errorbar(sizes,means,vars,'color',colors);    
        else
            errorbar(1:length(means),means,vars,'color',colors);    
        end
    end
    displayVal = makeResultsStruct(means,vars);
end

function [displayVal] = plotRelativePerformance(options,baselineFile,results,sizes,color)
    baselineResults = load(baselineFile);
    baselineResults = baselineResults.results.allResults;
    for i=1:numel(results)
        results{i}.aggregatedResults.baseline = ...
            baselineResults{i}.aggregatedResults.testResults;
        results{i}.aggregatedResults.baselinePerLabel = ...
            baselineResults{i}.aggregatedResults.testLabelMeasures;
        
    end
    field2 = 'testResults';
	field1 = 'baseline';
    
    [means,vars,l,h] = getRelativePerf(results,field1,...
        field2,options);
    means(isnan(means)) = 0;
    means(isinf(means)) = 2;
    vars(isnan(vars)) = 0;
    if ~isempty(vars)
        if sum(isinf(means)) > 0
            display('NaN');
        end        
        if ~options.c.vizMeasureCorrelation
            errorbar(sizes,means,vars,'color',color);
        end
        displayVal = makeResultsStruct(means,vars);
    else
        if ~options.c.vizMeasureCorrelation
            errorbar(sizes,means,l,h,'color',color);
        end
        displayVal = makeResultsStruct(means,[]);
        displayVal.lows = lows;
        displayVal.highs = h;
    end    
end

function [means,vars,lows,highs] = getRelativePerf(results,field1,field2,options)
    t = results{1}.aggregatedResults.(field1);
    if iscell(t)
        t = cell2mat(t);
    end
    numMeasureFields = size(t,2);
    means = zeros(numel(results),numMeasureFields);
    vars = [];
    highs = [];
    lows = [];
    if options.c.relativeType == Constants.RELATIVE_PERFORMANCE || ...
            options.c.relativeType == Constants.DIFF_PERFORMANCE
        vars = means;
    else
        highs = means;
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
        if options.c.relativeType == Constants.RELATIVE_PERFORMANCE || ...
                options.c.relativeType == Constants.DIFF_PERFORMANCE
            if options.c.relativeType == Constants.DIFF_PERFORMANCE                
                relativePerf = ResultsVector(y - x);                
            else
                relativePerf = ...
                    ResultsVector.GetRelativePerformance(x,y);
            end
            means(i,:) = relativePerf.getMean();
            vars(i,:) = relativePerf.getConfidenceInterval(options.c.confidenceInterval);
        elseif options.relativeType == Constants.CORRELATION
            [means(i),highs(i),lows(i)] = ResultsVector.GetCorrelation(x,y);
        else
            error('Unknown Relative Type');
        end
    end
end


function [vars] = getVariances(results,name,options)
    m = size(results{1}.aggregatedResults.(name),2);
    vars = zeros(numel(results),m);
    for i=1:numel(results);
        vars(i,:) = ...
            results{i}.aggregatedResults.(name).getConfidenceInterval(...
            options.c.confidenceInterval);
    end
end

function [means] = getMeans(results,name)
    m = size(results{1}.aggregatedResults.(name),2);
    means = zeros(numel(results),m);
    for i=1:numel(results);
        means(i,:) = ...
            results{i}.aggregatedResults.(name).getMean();
    end
end

function [sizes] = getSizes(results,sizeField)
    sizes = zeros(numel(results),1);
    for i=1:numel(results);
        sizes(i) = ...
            results{i}.experiment.(sizeField);
    end
end
%TODO: I think we don't need this as long as we specify the field to plot
%is 'repairAccuracy'
function [] = plotRepairResults(results,color,options)
    sizes = 0:size(results{1}.aggregatedResults.repairAccuracy,2)-1;
    plotResults(results,sizes,'repairAccuracy',color,options);    
end