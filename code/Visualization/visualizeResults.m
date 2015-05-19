function [f, returnStruct] = visualizeResults(options,f)
    if nargin < 1
        f = figure;
    end
    hold on;
    index = 1;   
    displayVals = {};
    allPlotConfigs = options.get('plotConfigs');
    numColors = length(allPlotConfigs);
    colors = hsv(4);
    fileManager = FileManager();
    fileExists = true(length(allPlotConfigs),1);
    sizes = [];
    method2colorMap = containers.Map;
    colorIdx=1;
    for i=1:length(allPlotConfigs)        
        plotConfigs = allPlotConfigs{i};                
        fileName = options.makeResultsFileName(plotConfigs.get('resultFileName'));
        if ~exist(fileName,'file')
            display([fileName ' doesn''t exist - skipping']);
            fileExists(i) = false;
            continue
        end
        lineStyle = '-';
        methodId = num2str(plotConfigs.get('methodId'));
        if isKey(method2colorMap,methodId)
            color = method2colorMap(methodId);
        else
            color = colors(colorIdx,:);
            method2colorMap(methodId) = color;
            colorIdx = colorIdx + 1;
        end
        if plotConfigs.has('lineStyle')
            lineStyle = plotConfigs.get('lineStyle');
        end
        smallFileName = getSmallFile(fileName);
        if exist(smallFileName,'file') && ProjectConfigs.useSavedSmallResults
            load(smallFileName);
        else
            %allResults = fileManager.load(fileName);
            allResults = load(fileName);
            allResults = allResults.results;
            measure = options.get('measure');
            allResults.computeLossFunction(measure);
            allResults.aggregateResults(measure);
            configs = allResults.mainConfigs;

            %learners = configs.get('learners');
            learners = allResults.allResults{1}.experiment.learner;
            learnerClassString = '';
            if numel(learners) > 0
                learnerClassString = class(learners);
            end                    
            [results] = allResults.getResultsForMethod(learnerClassString,options.c.resultQueries);
            Helpers.MakeDirectoryForFile(smallFileName);
            results{1}.splitResults = [];
            results{1}.splitMeasures = [];
            save(smallFileName,'results');
        end
        sizes = getSizes(results,options.c.sizeField);
        if options.has('sizeToUse')
            assert(~isempty(intersect(sizes,options.c.sizeToUse)));
            sizes = options.c.sizeToUse;
            [results] = getResultsWithSize(results,sizes);
        end        
        fieldToPlot = 'testResults';
        if plotConfigs.has('fieldToPlot')
            fieldToPlot = plotConfigs.get('fieldToPlot');
        end        
        if options.has('vizBarChartForField') && ...
                options.c.vizBarChartForField
            displayVals{end+1} = plotField(results,...
                fieldToPlot,color,lineStyle,options);
        else           
            displayVals{end+1} = plotResults(results,sizes,fieldToPlot,color,lineStyle,options);
        end
        index = index + 1;
    end
        
    leg = options.get('legend');
    
    %Plot is empty
    if index == 1
        leg = {};
    end
    if options.c.showLegend && ~isempty(leg) && ~options.c.showTable && any(fileExists) ...
            && options.get('showPlots')
        legend(leg(fileExists),'Location','southeast');
    end
    if options.c.showTable
        tableData = makeResultsTableData(displayVals);
        if isfield(options,'tableColumns') && ~isempty(options.c.tableColumns)
            assert(length(options.c.tableColumns) == length(leg));
            leg = options.c.tableColumns;
        end
        set(options.c.table,'Data',tableData,'ColumnName',leg,'RowName',options.c.dataSet);
    elseif options.get('showPlots')
        if options.has('axisToUse')
            axisToUse = options.c.axisToUse;    
            a = axis;
            if ~options.get('autoAdjustXAxis')
                a(1:2) = axisToUse(1:2);
            end
            if ~options.get('autoAdjustYAxis')
                a(3:4) = axisToUse(3:4);
            end            
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

function [s] = makeResultsStruct(means,vars,low)
    s = struct();
    s.means = means;
    if nargin == 2
        s.vars = vars;
    else
        s.high = vars;
        s.low = low;
    end
end

function [newResults] = getResultsWithSize(results,size)
    newResults = {};
    for i=1:length(results)
        r = results{i};
        %error('TODO: what if size is a vector?');
        if any(r.experiment.numLabeledPerClass == size)
            newResults{end+1} = r;
        end
    end
end

function [displayVal] = plotField(results,field,color,lineStyle,options)
    error('Color? Linestyle?');
    assert(length(results) == 1);
    vars = getVariances(results,field,options);
    means = getMeans(results,field);    
    %errorbar(1:length(means),means,vars,'color',color);    
    %bar(1:length(means),means,vars,'color',color);    
    barwitherr(vars,means,'r');    
    displayVal = makeResultsStruct(means,vars);
end

function [displayVal] = plotResults(results,sizes,field,colors,lineStyle,options)        
    vars = getVariances(results,field,options);
    %[high,low] = getVariances(results,field,options);
    means = getMeans(results,field);
    %if ~options.c.vizMeasureCorrelation
    if ~options.c.showTable && options.get('showPlots')
        if length(means) == length(sizes)
            errorbar(sizes,means,vars,'color',colors,'LineStyle',lineStyle);    
        else            
            if ProjectConfigs.useKSR
                a = ksr(1:length(means),means,2);
                plot(a.x,a.f,'color',colors);
            else
                
                errorbar(0:length(means)-1,means,vars,'color',colors,'LineStyle',lineStyle);
                %errorbar(1:length(means),means,low,high,'color',colors);    
            end
        end
    end
    displayVal = makeResultsStruct(means,vars);
    %displayVal = makeResultsStruct(means,high,low);
end

function [vars] = getVariances(results,name,options)
%function [high,low] = getVariances(results,name,options)
    m = size(results{1}.aggregatedResults.(name),2);
    vars = zeros(numel(results),m);
    %high = zeros(numel(results),m);
    %low = zeros(numel(results),m);
    for i=1:numel(results);
        v = ...
            results{i}.aggregatedResults.(name).getConfidenceInterval(...
            options.c.confidenceInterval);
        vars(i,:) = v;
        %high(i,:) = v(1,:);
        %low(i,:) = v(2,:);        
    end
end

function [means] = getMeans(results,name)
    m = size(results{1}.aggregatedResults.(name),2);
    means = zeros(numel(results),m);
    for i=1:numel(results);
        means(i,:) = results{i}.aggregatedResults.(name).getMean();
        %means(i,:) = results{i}.aggregatedResults.(name).getMedian();
    end
end

function [sizes] = getSizes(results,sizeField)
    sizes = zeros(numel(results),1);
    for i=1:numel(results);
        sizes(i) = ...
            results{i}.experiment.(sizeField);
    end
end

function [s] = getSmallFile(file)
    [dir,name,ext] = fileparts(file);
    s = [dir '/small/small_' name ext];
end
