function [f, returnStruct] = visualizeResults(options,f)
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
        if ~exist(fileName,'file')
            continue
        end
        allResults = load(fileName);
        allResults = allResults.results;
                
        allResults.aggregateMeasureResults(options.measureLoss);
        configs = allResults.mainConfigs;
        learners = configs.get('learners');
        
        %TODO: Find better way to do this loop
        learnerIdx = 1;
        while(true)
            %TODO: Find better way to do this loop
            if numel(learners) < learnerIdx && learnerIdx > 1
                break;
            end
            hasPreTM = configs.has('preTransferMeasures') && ...
                ~isempty(configs.get('preTransferMeasures'));
            hasPostTM = configs.has('postTransferMeasures') && ...
                ~isempty(configs.get('postTransferMeasures'));
            hasTransferMethod = configs.has('transferMethodClass');            
            hasDR = isKey(configs,'drMethod');
            
            isMeasureFile = hasPostTM || hasPreTM;
            learnerClassString = '';
            if numel(learners) > 0
                learnerClassString = class(learners{learnerIdx});
            end            
            learnerIdx = learnerIdx + 1;
            if ~isMeasureFile && ...
                ~shouldShowResults(learnerClassString,options.methodsToShow)
                continue;
            end            
            [results] = allResults.getResultsForMethod(learnerClassString);
            if ~isMeasureFile && isempty(results)
                continue;
            end
            
            hasTestResults = numel(results) > 0 && ...
                numel(results{1}.aggregatedResults.testResults) > 0;
            
            legendName = '';
            if ~isempty(learnerClassString)
                legendName = Method.GetDisplayName(learnerClassString,configs);
            end
            if hasDR
                drName = DRMethod.GetDisplayName(configs.get('drMethod'),configs);
                legendName = [drName '-' legendName];                
            end
            if hasTransferMethod
                transferName = ...
                    Transfer.GetDisplayName(configs.get('transferMethodClass'),...
                    allResults.mainConfigs);
                legendName = [legendName ';' transferName];
            end  
            if hasPostTM
                measures = configs.get('postTransferMeasures');
                dispName = TransferMeasure.GetDisplayName(measures,configs);
                leg{index} = [legendName ';' dispName];
            end
            if isfield(options,'showRepair') && options.showRepair
                plotRepairResults();                
            else
                if isKey(configs,'numLabeledPerClass')
                    numTrain = length(configs.get('numLabeledPerClass'));
                else
                    sizes = getSizes(results,options.xAxisField);
                    numTrain = length(sizes);
                end
                if numTrain > 1
                    sizes = getSizes(results,options.xAxisField);
                    if options.showRelativePerformance && hasTestResults
                        plotRelativePerformance(options,...
                            baselineFiles,results,sizes,configs,colors,index,legendName,leg);
                        legendName = ['Relative Acc: ' learnerName];
                        leg{index} = legendName;
                        index = index + 1;
                    else
                        if hasTestResults
                            [index,leg] = plotTestResults(options,results,sizes,colors,...
                                index,legendName,leg);
                        end
                        if hasPostTM || hasPreTM
                            [index,leg] = plotMeasures(options,results,sizes,configs,...
                                hasPostTM,hasPreTM,colors,index,legendName,leg);
                        end
                    end
                elseif configs.has('numVecs') && length(configs.get('numVecs')) > 1
                    numVecs = configs.get('numVecs');
                    [index,leg] = plotTestResults(options,results,numVecs,colors,...
                                index,legendName,leg);
                elseif configs.has('tau') && length(configs.get('tau')) > 1
                    tau = configs.get('tau');
                    [index,leg] = plotTestResults(options,results,tau,colors,...
                                index,legendName,leg);
                else
                    error('What should we visualize?');
                end
            end
            if ~hasTestResults
                %display('visualizeResults.m: Hack for measure results - fix later');
                break;
            end            
        end
    end       
    if options.showLegend && ~isempty(leg)
        legend(leg);
    end
    axisToUse = options.axisToUse;    
    if isfield(options,'showRepair') && options.showRepair        
        xAxisLabel = options.xAxisDisplay;     
    elseif exist('results','var')      
        numTrain = results{1}.splitResults{1}.trainingDataMetadata.numTrain;
        numTest = results{1}.splitResults{1}.trainingDataMetadata.numTest;
        xAxisLabel = [options.xAxisDisplay ' ('];
        if isfield(results{1}.splitResults{1}.trainingDataMetadata,'numSourceLabels')
            numSourceLabels = ...
                results{1}.splitResults{1}.trainingDataMetadata.numSourceLabels;
            xAxisLabel = [xAxisLabel 'Num Source Labels = ' num2str(numSourceLabels) ', '];
        end
        xAxisLabel = [xAxisLabel num2str(numTrain) '/' num2str(numTest) ')'];
    else
        xAxisLabel = '';
    end
    axis(axisToUse);
    xlabel(xAxisLabel,'FontSize',8);
        ylabel(options.yAxisDisplay,'FontSize',8);
    hold off;    
    returnStruct = struct();
    returnStruct.numItemsInLegend = length(leg);
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
        measures = configs.get('postTransferMeasures');
        dispName = TransferMeasure.GetDisplayName(measures{1},configs);
        leg{index} = ['Relative Measure: ' dispName];
        index = index + 1;
    else
        if options.showPostTransferMeasures && hasPostTM  
            displayName = 'PostTM';
            plotMeasureResults(options,configs,results,sizes,...
                'postTransferMeasures','PostTMResults',displayName,...
                learnerName,leg,index,colors);
            measureObj = configs.get('postTransferMeasures');    
            dispName = measureObj.getDisplayName();
            leg{index} = [displayName ':' learnerName ':' dispName];
            index = index + 1;
        end
        if options.showPreTransferMeasures && hasPreTM
            displayName = 'PreTM';
            plotMeasureResults(options,configs,results,sizes,...
                'preTransferMeasures','PreTMResults',displayName,...
                learnerName,leg,index,colors);
            measureObj = configs.get('preTransferMeasures');    
            dispName = measureObj.getDisplayName();
            leg{index} = [displayName ':' learnerName ':' dispName];
            index = index + 1;
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
            m = r.aggregatedResults.trainingDataMetadata;
            r.aggregatedResults = measureObj.aggregateResults(r.splitMeasures);
            r.aggregatedResults.trainingDataMetadata = m;
            resultsToUse{i} = r;
        end
    end
    if isfield(options,'usePerLabel') && options.usePerLabel
        vars = getVariances(resultsToUse,'testLabelMeasures');
        means = getMeans(resultsToUse,'testLabelMeasures');
        if options.labelToShow > 0
            means = means(:,options.labelToShow);
            vars = vars(:,options.labelToShow);
        else
            means = mean(means,2);
            vars = mean(vars,2);
        end
    else
        vars = getVariances(resultsToUse,'testResults');
        means = getMeans(resultsToUse,'testResults');
    end
    if options.showTest
        errorbar(sizes,means,vars,'color',colors(index,:));
        legName = learnerName;
        if options.showTrain
            legName = [learnerName ', Test'];
        end
        leg{index} = legName;
        index = index+1;
    end
    if options.showTrain
        vars = getVariances(resultsToUse,'trainResults');
        means = getMeans(resultsToUse,'trainResults');
        errorbar(sizes,means,vars,'color',colors(index,:));
        leg{index} = [learnerName ', Train'];
        index = index+1;
    end
end

function [] = plotRelativePerformance(options,baselineFiles,results,sizes,configs,colors,index,learnerName,leg)
    d = getProjectDir();
    baselineFile = [d '/results/' options.prefix '/' options.dataSet '/' baselineFiles{1}];
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
    %leg{index} = ['Relative Acc: ' learnerName];
    %index = index+1;
end

function [] = plotMeasureResults(options,configs,results,sizes,field,...
    resultField,displayName,learnerName,leg,index,colors)
    measureObj = configs.get(field);
    if ~isKey(options.measuresToShow,class(measureObj))
        return;
    end
    %dispName = measureObj.getDisplayName();
    yVals = getMeans(results,resultField);
    yValsBars = getVariances(results,resultField);
    xVals = sizes;
    errorbar(xVals,yVals,yValsBars,'color',colors(index,:));
    %leg{index} = [displayName ':' learnerName ':' dispName];
    %index = index+1;
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
            vars(i,:) = relativePerf.getConfidenceInterval();        
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
            results{i}.splitResults{1}.trainingDataMetadata.(sizeField);
    end
end

function [b] = shouldShowResults(learnerClassString,methodsToShow)
    b =  isKey(methodsToShow,learnerClassString) && ...
            methodsToShow(learnerClassString);
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