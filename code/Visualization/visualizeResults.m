function [f, returnStruct] = visualizeResults(options,f)
    if nargin < 1
        f = figure;
    end
    hold on;
    leg = {};  
    numColors = options.c.numColors;
    colors = colormap(hsv(numColors));

    legendNameParams = {...
        MainConfigs.OutputNameStruct('learners','',[],true,false),...
        MainConfigs.OutputNameStruct('drMethod','',[],true,false),...
        MainConfigs.OutputNameStruct('transferMethodClass','',[],true,false)...
    };
    index = 1;   
    displayVals = {};
    allPlotConfigs = options.get('plotConfigs');
    for i=1:length(allPlotConfigs)
        legendName = '';
        plotConfigs = allPlotConfigs{i};        
        if length(options.c.dataSet) > 1
            results = struct();
            results.measureResults = {};
            results.baselineResults = {};
            results.methodResults = {};
            for dataSetIdx=1:length(options.c.dataSet)
                dataSet = options.c.dataSet{dataSetIdx};
                fileName = options.makeResultsFileName(dataSet,...
                    plotConfigs.get('resultFileName'));
                baselineFileName = options.makeResultsFileName(dataSet,...
                    plotConfigs.get('baselineFile'));
                methodFileName = options.makeResultsFileName(dataSet,...
                    plotConfigs.get('methodFileName'));
                if ~exist(fileName,'file')
                    continue;
                end
                measureResults = load(fileName);
                %configs.get('postTransferMeasures').set('measureLoss',measureLoss);                                
                measureResults.results.aggregateMeasureResults(plotConfigs.get('measureLoss'));
                results.measureResults{end+1} = measureResults.results;
                baselineResults = load(baselineFileName);
                results.baselineResults{end+1} = baselineResults.results;
                methodResults = load(methodFileName);
                results.methodResults{end+1} = methodResults.results;
            end
            allResults = plotConfigs.c.multiMeasure.computeMeasure(results);
            configs = methodResults.results.mainConfigs;
            measureObj = measureResults.results.mainConfigs.get('postTransferMeasures');
            legendName = measureObj.getDisplayName();
        else
            fileName = options.makeResultsFileName(options.c.dataSet{1},...
                plotConfigs.get('resultFileName'));
            baselineFile = options.makeResultsFileName(options.c.dataSet{1},...
                plotConfigs.get('baselineFile'));
            if ~exist(fileName,'file')
                display([fileName ' doesn''t exist - skipping']);
                continue
            end
            allResults = load(fileName);
            allResults = allResults.results;
            configs = allResults.mainConfigs;
        end
                                
        hasPreTM = configs.hasNonempty('preTransferMeasures');
        hasPostTM = configs.hasNonempty('postTransferMeasures');
        isMeasureFile = hasPostTM || hasPreTM;
        if isMeasureFile
            measureLoss = plotConfigs.get('measureLoss');
            if hasPreTM                
                configs.get('preTransferMeasures').set('measureLoss',measureLoss);
            end
            if hasPostTM
                configs.get('postTransferMeasures').set('measureLoss',measureLoss);
            end
            allResults.aggregateMeasureResults(plotConfigs.get('measureLoss'));
        end
        learners = configs.get('learners');
        learnerClassString = '';
        if numel(learners) > 0
            learnerClassString = class(learners);
        end                    
        [results] = allResults.getResultsForMethod(learnerClassString,options.c.resultQueries);
        if ~isMeasureFile && isempty(results)
            continue;
        end

        hasTestResults = numel(results) > 0 && ...
            numel(results{1}.aggregatedResults.testResults) > 0;        
        legendName = [legendName ',' configs.stringifyFields(legendNameParams,'-')];
        
        if isfield(options,'showRepair') && options.c.showRepair
            plotRepairResults();                
        else
            sizes = getSizes(results,options.c.xAxisField);                          
            if configs.hasMoreThanOne('numVecs')
                error('TODO');
                numVecs = configs.get('numVecs');
                displayVals{end+1} = plotResults(results,numVecs,colors(index,:));
            elseif configs.hasMoreThanOne('tau')
                error('TODO');
                tau = configs.get('tau');
                displayVals{end+1} = plotResults(results,tau,colors(index,:));
            else
                numTrain = length(sizes);  
                if options.c.showRelativePerformance && hasTestResults
                    displayVals{end+1} = plotRelativePerformance(options,...
                        baselineFile,results,sizes,colors(index,:));
                    legendName = ['Relative Acc: ' legendName];
                    leg{index} = legendName;
                    index = index + 1;
                else
                    if hasTestResults
                        if options.c.showTest
                            displayVals{end+1} = plotResults(results,sizes,'testResults',colors(index,:));
                            legName = legendName;
                            if options.c.showTrain
                                legName = [legName ', Test'];
                            end
                            if plotConfigs.has('multiMeasure')
                                legName = [plotConfigs.c.multiMeasure.getPrefix() ':' legName];
                            end
                            leg{index} = legName;
                            index = index+1;
                        end
                        if options.c.showTrain
                            displayVals{end+1} = plotResults(results,sizes,'trainResults',colors(index,:));
                            leg{index} = [legendName ', Train'];
                            index = index+1;
                        end
                    end
                    if hasPostTM && hasPreTM && options.c.showRelativeMeasures
                        [index,leg,displayVals{end+1}] = plotRelativeMeasures(options,results,sizes,configs,...
                            hasPostTM,hasPreTM,colors,index,legendName,leg);
                    else
                        if hasPostTM && options.c.showPostTransferMeasures
                            measureObj = configs.get('postTransferMeasures');                            
                            displayVals{end+1} = plotResults(results,sizes,'PostTMResults',colors(index,:));
                            dispName = measureObj.getDisplayName();
                            leg{index} = ['PostTM:' legendName ':' dispName];
                            index = index + 1;
                        end
                        if hasPreTM && options.c.showPreTransferMeasures
                            measureObj = configs.get('preTransferMeasures');
                            displayVals{end+1} = plotResults(results,sizes,'PreTMResults',colors(index,:));
                            dispName = measureObj.getDisplayName();
                            leg{index} = ['PreTM:' legendName ':' dispName];
                            index = index + 1;
                        end
                    end
                end
            end
        end        
    end       
    if options.has('legend')
        leg = options.get('legend');
    end
    if options.c.showLegend && ~isempty(leg) && ~options.c.showTable
        legend(leg,'Location','southeast');
    end
    if options.c.showTable
        tableData = makeResultsTableData(displayVals);
        if isfield(options,'tableColumns') && length(options.c.tableColumns) > 0
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
        if isfield(options,'showRepair') && options.c.showRepair        
            xAxisLabel = options.c.xAxisDisplay;     
        elseif exist('results','var')      
            numTrain = results{1}.splitResults{1}.trainingDataMetadata.numTrain;
            numTest = results{1}.splitResults{1}.trainingDataMetadata.numTest;
            xAxisLabel = [options.c.xAxisDisplay ' ('];
            if isfield(results{1}.splitResults{1}.trainingDataMetadata,'numSourceLabels')
                numSourceLabels = ...
                    results{1}.splitResults{1}.trainingDataMetadata.numSourceLabels;
                xAxisLabel = [xAxisLabel 'Num Source Labels = ' num2str(numSourceLabels) ', '];
            end
            xAxisLabel = [xAxisLabel num2str(numTrain) '/' num2str(numTest) ')'];
        else
            xAxisLabel = '';
        end    
        xlabel(xAxisLabel,'FontSize',8);
        ylabel(options.c.yAxisDisplay,'FontSize',8);
    end
    hold off;    
    returnStruct = struct();
    returnStruct.numItemsInLegend = length(leg);
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

function [index,leg,displayVal] = plotRelativeMeasures(options,results,sizes,configs,...
    hasPostTM,hasPreTM,colors,index,learnerName,leg)
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
    errorbar(sizes,means,vars,'color',colors(index,:));
    measures = configs.get('postTransferMeasures');
    dispName = TransferMeasure.GetDisplayName(measures,configs);
    leg{index} = ['Relative Measure: ' dispName];
    index = index + 1;
    displayVal = makeResultsStruct(means,vars);
end

function [displayVal] = plotResults(results,sizes,field,colors)        
    vars = getVariances(results,field);
    means = getMeans(results,field);
    %if length(sizes) > 1
        errorbar(sizes,means,vars,'color',colors);    
    %end
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
        %if length(sizes) > 1
            errorbar(sizes,means,vars,'color',color);
        %end
        displayVal = makeResultsStruct(means,vars);
    else
        %if length(sizes) > 1
            errorbar(sizes,means,l,h,'color',color);
        %end
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
            vars(i,:) = relativePerf.getConfidenceInterval();        
        elseif options.relativeType == Constants.CORRELATION
            [means(i),highs(i),lows(i)] = ResultsVector.GetCorrelation(x,y);
        else
            error('Unknown Relative Type');
        end
    end
end


function [vars] = getVariances(results,name)
    m = size(results{1}.aggregatedResults.(name),2);
    vars = zeros(numel(results),m);
    for i=1:numel(results);
        vars(i,:) = ...
            results{i}.aggregatedResults.(name).getConfidenceInterval();
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

function [] = plotRepairResults()
    repairMethodString = configs.get('repairMethod');
    transferRepairName = ...
        TransferRepair.GetDisplayName(repairMethodString,configs);
    legendName = [transferRepairName ';' legendName];
    measureClassName = configs.get('measureClass');
    measureObject = Measure.ConstructObject(measureClassName,configs);
    results = results{1};
    numIterations = configs.get('numIterations');
    numSplits = results.numSplits;
    if options.showRepairChange
        error('Update');
        meanMeasureImprovements = zeros(numSplits,numIterations+1);
        for split=1:numSplits
            splitResults = results.splitResults{split}; 
            repairResults1 = splitResults.repairResults{1};
            labeledTrainData = find(repairResults1.trainActual > 0 & ...
                repairResults1.trainType == Constants.TARGET_TRAIN);
            labeledTrainY = repairResults1.trainActual(labeledTrainData);
            numLabeledTrain = length(labeledTrainY);
            splitMeasureScores = zeros(numLabeledTrain,numIterations+1);
            splitTrainFU = zeros(numLabeledTrain,numIterations+1);
            splitRepairScores = zeros(numLabeledTrain,numIterations+1);
            splitIsIncorrect = zeros(numLabeledTrain,numIterations+1);
            trainIndsToUse = zeros(1,numIterations+1);
            trainIndsToFocusOn = zeros(numLabeledTrain,numIterations+1);
            measureScores = zeros(1,numIterations+1);
            trainFU = zeros(1,numIterations+1);
            for itr=1:numIterations+1
                trResults = splitResults.repairResults{itr};
                measureResults = splitResults.transferMeasureMetadata{itr};
                repairMetadata = splitResults.repairMetadata{itr};

                splitMeasureScores(:,itr) = Helpers.SelectFromRows(...
                    measureResults.labeledTargetScores,labeledTrainY);                            
                splitTrainFU(:,itr) = Helpers.SelectFromRows(...
                    trResults.trainFU(labeledTrainData,:),labeledTrainY);


                if itr > 1
                    splitRepairScores(:,itr) = Helpers.SelectFromRows(... 
                        repairMetadata.targetScores,labeledTrainY);                            
                    splitIsIncorrect(:,itr) = repairMetadata.isIncorrect;
                    trainIndsToFocusOn(:,itr) = repairMetadata.labeledTargetIndsToFocusOn;
                    trainIndsToUse(itr) = repairMetadata.trainIndsToUse;
                end
            end
            for itr=2:length(trainIndsToUse)
                ind = find(trainIndsToFocusOn(:,itr));
                measureScores(itr,:) = splitMeasureScores(ind,:);
                meanMeasureImprovements(split,itr) = ...
                    measureScores(itr,itr)-measureScores(itr,itr-1);
            end
        end
        measureIncreaseResults = ResultsVector(meanMeasureImprovements);
        mMIR = measureIncreaseResults.getMean();
        vMIR = measureIncreaseResults.getConfidenceInterval();
        errorbar(0:numIterations,mMIR,vMIR,'color',colors(index,:));
        leg{index} = [legendName ':' 'Measure Increase'];
        index = index + 1;
    else
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
        vPT = PTResults.getConfidenceInterval();
        errorbar(0:numIterations,mPT,vPT,'color',colors(index,:));
        leg{index} = [legendName ':' 'Transfer Measure'];
        index = index+1;

        mAcc = accResults.getMean();
        mAcc
        vAcc = accResults.getConfidenceInterval();
        errorbar(0:numIterations,mAcc,vAcc,'color',colors(index,:));
        leg{index} = [legendName ':' 'Repaired Acc'];
        index = index+1;
    end
end