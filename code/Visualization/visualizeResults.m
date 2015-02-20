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
        measure = options.get('measure');
        allResults.computeLossFunction(measure);
        allResults.aggregateResults(measure);
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
        if options.has('axisToUse')
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
    %if ~options.c.vizMeasureCorrelation
    if true
        if length(means) == length(sizes)
            errorbar(sizes,means,vars,'color',colors);    
        else
            errorbar(1:length(means),means,vars,'color',colors);    
        end
    end
    displayVal = makeResultsStruct(means,vars);
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
