function [f] = visualizeResults(options,f)
    if nargin < 1
        f = figure;
    end
    hold on;
    leg = {};
    baselineFiles = {};    
    files = [options.baselineFiles options.fileNames];    
    numColors = options.numColors;
    colors = colormap(hsv(numColors));
    if options.showRelativePerformance
        numBaselineFiles = numel(options.baselineFiles);
        assert(numBaselineFiles > 0);
        baselineFiles = files(1:numBaselineFiles);
        files = files(numBaselineFiles+1:end);
    end

    index = 1;    
    measureVals = {};
    transferPerfVals = [];
    for i=1:numel(files)
        fileName = [getProjectDir() '/results/' options.prefix '/' options.dataSet '/' files{i}];        
        allResults = load(fileName);
        allResults = allResults.results;
                
        configs = Configs(allResults.configs);
        methodClasses = configs.getMethodClasses();
        for j=1:numel(methodClasses)            
            methodClassString = methodClasses{j};            
            if ~isKey(options.methodsToShow,methodClassString) || ...
                    ~options.methodsToShow(methodClassString)
                continue;
            end            
            
            [results] = allResults.getResultsForMethod(methodClassString);
            hasPostTM = configs.hasPreTransferMeasures();
            hasPreTM = configs.hasPostTransferMeasures();
            hasTransferMethod = configs.hasTransferMethod();
            hasTestResults = isfield(results{1}.aggregatedResults,'testResults');
            
            learnerName = Method.GetDisplayName(methodClassString,configs.configs);
            drName = DRMethod.GetDisplayName(configs.configs('drMethod'),configs.configs);
            learnerName = [drName '-' learnerName];                
            if hasTransferMethod
                transferName = ...
                    Transfer.GetDisplayName(configs.getTransferMethod(),allResults.configs);
                learnerName = [learnerName ';' transferName];
            end                                
            if isfield(options,'showRepair') && options.showRepair
                repairMethodString = configs.configs('repairMethod');
                transferRepairName = ...
                    TransferRepair.GetDisplayName(repairMethodString,configs.configs);
                learnerName = [transferRepairName ';' learnerName];
                measureClassName = configs.configs('measureClass');
                measureObject = Measure.ConstructObject(measureClassName,configs);
                results = results{1};
                numIterations = configs.configs('numIterations');
                numSplits = results.numSplits;
                postTransferVals = zeros(numIterations,numSplits);
                repairedAcc = zeros(numIterations,numSplits);
                for itr=1:numIterations+1
                    for split=1:numSplits
                        splitResults = results.splitResults{split};
                        postTransferVals(itr,split) = ...
                            splitResults.postTransferMeasureVal{itr};
                        repairResults = splitResults.repairResults{itr};
                        measureResults = measureObject.evaluate(repairResults);
                        repairedAcc(itr,split) = ...
                            measureResults.testPerformance;                            
                    end
                end
                PTResults = ResultsVector(postTransferVals');
                accResults = ResultsVector(repairedAcc');
                mPT = PTResults.getMean();
                vPT = PTResults.getVar();                
                errorbar(0:numIterations,mPT,vPT,'color',colors(index,:));
                leg{index} = [learnerName ':' 'Transfer Measure'];
                index = index+1;
                
                mAcc = accResults.getMean();
                vAcc = accResults.getVar();
                errorbar(0:numIterations,mAcc,vAcc,'color',colors(index,:));
                leg{index} = [learnerName ':' 'Repaired Acc'];
                index = index+1;
            else
                sizes = getSizes(results,options.xAxisField);
                if isfield(options,'binPerformance') && options.binPerformance
                    if hasPostTM
                        measureVals{end+1} = getMeasurePerformanceForSize(results,options.numLabelsToUse,sizes);
                        measures = configs.getPostTransferMeasures();
                        dispName = TransferMeasure.GetDisplayName(measures{1},configs.configs);
                        leg{index} = [learnerName ';' dispName];
                        index = index + 1;
                    elseif hasTestResults
                        transferPerfVals = getMeasurePerformanceForSize(results,options.numLabelsToUse,sizes);
                    else
                        error('');
                    end
                elseif options.showRelativePerformance && hasTestResults
                    [index,leg] = plotRelativePerformance(options,...
                        baselineFiles,results,sizes,configs,colors,index,learnerName,leg);
                else
                    if hasTestResults
                        [index,leg] = plotTestResults(options,results,sizes,colors,...
                            index,learnerName,leg);
                    end
                    if hasPostTM || hasPreTM
                        [index,leg] = plotMeasures(options,results,sizes,configs,...
                            hasPostTM,hasPreTM,colors,index,learnerName,leg);
                    end
                end
            end
            if ~hasTestResults
                display('Hack - fix this later');
                break;
            end
        end
    end    
    if isfield(options,'binPerformance') && options.binPerformance
        [~,inds] = sort(transferPerfVals);
        measureRange = [Inf -Inf];
        for i=1:length(measureVals)
            measureRange(1) = min(measureRange(1),min(measureVals{i}));
            measureRange(2) = max(measureRange(1),max(measureVals{i}));
        end
        xVals = Helpers.NormalizeRange(transferPerfVals(inds));
        for i=1:length(measureVals)
            yVals = Helpers.NormalizeRange(measureVals{i},measureRange);
            plot(xVals,yVals,'color',colors(i,:),'Marker','x');
        end
        plot([0 1],[0 1],'color',colors(i+1,:),'LineStyle','--');
        leg{end+1} = 'Perfect Correlation';
    end
    if options.showLegend
        legend(leg);
    end
    axisToUse = options.axisToUse;    
    if isfield(options,'showRepair') && options.showRepair        
        xAxisLabel = options.xAxisDisplay;
    elseif isfield(options,'binPerformance') && options.binPerformance
        xAxisLabel = 'Normalized Accuracy';                      
        axisToUse = [0 1 0 1];        
    else    
        numTrain = results{1}.aggregatedResults.metadata.numTrain;
        numTest = results{1}.aggregatedResults.metadata.numTest;
        xAxisLabel = [options.xAxisDisplay ' ('];
        if isfield(results{1}.aggregatedResults.metadata,'numSourceLabels')
            numSourceLabels = ...
                results{1}.aggregatedResults.metadata.numSourceLabels;
            xAxisLabel = [xAxisLabel 'Num Source Labels = ' num2str(numSourceLabels) ', '];
        end
        xAxisLabel = [xAxisLabel num2str(numTrain) '/' num2str(numTest) ')'];
    end
    axis(axisToUse);
    xlabel(xAxisLabel,'FontSize',8);
        ylabel(options.yAxisDisplay,'FontSize',8);
    hold off;    
end

function [index,leg] = plotMeasures(options,results,sizes,configs,...
    hasPostTM,hasPreTM,colors,index,learnerName,leg)
    if hasPostTM && hasPreTM && options.showRelativeMeasures
        if ~options.usePerLabel
            field2 = 'PostTMResults';
            field1 = 'PreTMResults';
        else
            field2 = 'postTransferPerLabelMeasures';
            field1 = 'preTransferPerLabelMeasures';
        end
        [means,vars,lows,ups] = getRelativePerf(results,...
            field1,field2,options);
        means(isnan(means)) = 0;
        means(isinf(means)) = 2;
        vars(isnan(vars)) = 0;
        if options.usePerLabel
            if options.labelToShow > 0
                means = means(:,options.labelToShow);
                vars = vars(:,options.labelToShow);
            else
                means = mean(means,2);
                vars = mean(vars,2);
            end
        end
        errorbar(sizes,means,vars,'color',colors(index,:));
        measures = configs.getPostTransferMeasures();
        dispName = TransferMeasure.GetDisplayName(measures{1},configs.configs);
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

function [index,leg] = plotTestResults(options,results,sizes,colors,index,learnerName,leg)
    resultsToUse = results;
    if isfield(options,'measure')
        measureObj = Measure.ConstructObject(options.measure,options.measureConfigs);
        for i=1:length(resultsToUse)
            r = resultsToUse{i};
            for j=1:length(r.splitResults)
                r.splitMeasures{j} = measureObj.evaluate(r.splitResults{j});
            end
            m = r.aggregatedResults.metadata;
            r.aggregatedResults = measureObj.aggregateResults(r.splitMeasures);
            r.aggregatedResults.metadata = m;
            resultsToUse{i} = r;
        end
    end
    if isfield(options,'usePerLabel') && options.usePerLabel
        vars = getVariances(resultsToUse,'testLabelMeasures',-1);
        means = getMeans(resultsToUse,'testLabelMeasures',-1);
        if options.labelToShow > 0
            means = means(:,options.labelToShow);
            vars = vars(:,options.labelToShow);
        else
            means = mean(means,2);
            vars = mean(vars,2);
        end
    else
        vars = getVariances(resultsToUse,'testResults',-1);
        means = getMeans(resultsToUse,'testResults',-1);
    end
    errorbar(sizes,means,vars,'color',colors(index,:));
    legName = learnerName;
    if options.showTrain
        legName = [learnerName ', Test'];
    end
    leg{index} = legName;
    index = index+1;
    if options.showTrain
        vars = getVariances(resultsToUse,'trainResults',-1);
        means = getMeans(resultsToUse,'trainResults',-1);
        errorbar(sizes,means,vars,'color',colors(index,:));
        leg{index} = [learnerName ', Train'];
        index = index+1;
    end
end

function [index,leg] = plotRelativePerformance(options,baselineFiles,results,sizes,configs,colors,index,learnerName,leg)
    baselineFile = ['results/' options.prefix '/' options.dataSet '/' baselineFiles{1}];
    baselineResults = load(baselineFile);
    baselineResults = baselineResults.results.allResults;
    for i=1:numel(results)
        results{i}.aggregatedResults.baseline = ...
            baselineResults{i}.aggregatedResults.testResults;
        results{i}.aggregatedResults.baselinePerLabel = ...
            baselineResults{i}.aggregatedResults.testLabelMeasures;
        
    end
    if ~options.usePerLabel
        field2 = 'testResults';
        field1 = 'baseline';
    else
        field2 = 'testLabelMeasures';
        field1 = 'baselinePerLabel';
    end
    
    [means,vars,l,u] = getRelativePerf(results,field1,...
        field2,options);
    means(isnan(means)) = 0;
    means(isinf(means)) = 2;
    vars(isnan(vars)) = 0;
    if ~isempty(vars)
        if sum(isinf(means)) > 0
            display('NaN');
        end
        if options.usePerLabel
            if options.labelToShow > 0
                means = means(:,options.labelToShow);
                vars = vars(:,options.labelToShow);
            else
                means = mean(means,2);
                vars = mean(vars,2);
            end
        end
        errorbar(sizes,means,vars,'color',colors(index,:));
    else
        errorbar(sizes,means,l,u,'color',colors(index,:));
    end
    %dispName = TransferMeasure.GetDisplayName(measures{k},configs);
    leg{index} = ['Relative Acc: ' learnerName];
    index = index+1;
end

function [leg,index] = plotMeasureResults(options,configs,results,sizes,field,...
    resultField,displayName,learnerName,leg,index,colors)
    measures = configs.getConfig(field);
    for k=1:numel(measures)
        if ~isKey(options.measuresToShow,measures{k})
            continue;
        end
        dispName = TransferMeasure.GetDisplayName(measures{k},configs.configs);
        yVals = getMeans(results,resultField,k);
        yValsBars = getVariances(results,resultField,k);
        xVals = sizes;
        errorbar(xVals,yVals,yValsBars,'color',colors(index,:));
        leg{index} = [displayName ':' learnerName ':' dispName];
        index = index+1;
    end
end

function [means,vars,lows,ups] = getRelativePerf(results,field1,field2,options)
    t = results{1}.aggregatedResults.(field1);
    if iscell(t)
        t = cell2mat(t);
    end
    numMeasureFields = size(t,2);
    means = zeros(numel(results),numMeasureFields);
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
            means(i,:) = relativePerf.getMean();
            vars(i,:) = relativePerf.getVar();        
        elseif options.relativeType == Constants.CORRELATION
            [means(i),ups(i),lows(i)] = ResultsVector.GetCorrelation(x,y);
        else
            error('Unknown Relative Type');
        end
    end
end

function [vals] = getMeasurePerformanceForSize(results,numLabelsToUse,sizes)
    vals = zeros(1,1);
    resultIndex = find(sizes == numLabelsToUse);
    assert(length(resultIndex) == 1);
    r = results{resultIndex};
    if ~isempty(r.splitResults{1}.postTransferMeasureVal)
        for i=1:length(r.splitResults)
            vals(i) = r.splitResults{i}.postTransferMeasureVal{1};
        end
    else
        vals = double(r.aggregatedResults.testResults);
    end
    vals = vals(:);
end

function [vars] = getVariances(results,name,index)
    if index < 0
        m = size(results{1}.aggregatedResults.(name),2);
    else
        m = size(results{1}.aggregatedResults.(name){index},2);
    end
    vars = zeros(numel(results),m);
    for i=1:numel(results);
        if index < 0
            vars(i,:) = ...
                results{i}.aggregatedResults.(name).getVar();
        else
            vars(i,:) = ...
                results{i}.aggregatedResults.(name){index}.getVar();
        end
    end
end

function [means] = getMeans(results,name,index)
    if index < 0
        m = size(results{1}.aggregatedResults.(name),2);
    else
        m = size(results{1}.aggregatedResults.(name){index},2);
    end
    means = zeros(numel(results),m);
    for i=1:numel(results);
        if index < 0
            means(i,:) = ...
                results{i}.aggregatedResults.(name).getMean();
        else
            means(i,:) = ...
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
