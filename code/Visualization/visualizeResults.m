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
        if ~exist(fileName,'file')
            continue
        end
        allResults = load(fileName);
        allResults = allResults.results;
                
        configs = allResults.configs;
        learners = configs.get('learners');
        
        %TODO: Find better way to do this loop
        learnerIdx = 1;
        while(true)
            hasPostTM = configs.has('preTransferMeasures');
            hasPreTM = configs.has('postTransferMeasures');
            hasTransferMethod = configs.has('hasTransferMethod');            
            hasDR = isKey(configs,'drMethod');
            
            isMeasureFile = hasPostTM || hasPreTM;
            learnerClassString = '';
            if numel(learners) > 0
                learnerClassString = class(learners{learnerIdx});
            end            
            learnerIdx = learnerIdx + 1;
            if ~isMeasureFile && ...
                (strcmp(learnerClassString,'') || ...
                    ~isKey(options.methodsToShow,learnerClassString) || ...
                    ~options.methodsToShow(learnerClassString) || ...
                    numel(option.methodsToShow) == 0)
                continue;
            end            
            [results] = allResults.getResultsForMethod(learnerClassString);
            if ~isMeasureFile && isempty(results)
                continue;
            end
            
            hasTestResults = numel(results) > 0 && ...
                numel(results{1}.aggregatedResults.testResults) > 0;
            learnerName = Method.GetDisplayName(learnerClassString,configs);
            if hasDR
                drName = DRMethod.GetDisplayName(configs.get('drMethod'),configs);
                learnerName = [drName '-' learnerName];                
            end
            if hasTransferMethod
                transferName = ...
                    Transfer.GetDisplayName(configs.get('transferMethodClass'),...
                    allResults.configs);
                learnerName = [learnerName ';' transferName];
            end                                
            if isfield(options,'showRepair') && options.showRepair
                repairMethodString = configs.get('repairMethod');
                transferRepairName = ...
                    TransferRepair.GetDisplayName(repairMethodString,configs);
                learnerName = [transferRepairName ';' learnerName];
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
                    leg{index} = [learnerName ':' 'Measure Increase'];
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
                    leg{index} = [learnerName ':' 'Transfer Measure'];
                    index = index+1;
                    
                    mAcc = accResults.getMean();
                    mAcc
                    vAcc = accResults.getConfidenceInterval();
                    errorbar(0:numIterations,mAcc,vAcc,'color',colors(index,:));
                    leg{index} = [learnerName ':' 'Repaired Acc'];
                    index = index+1;
                end                
            else
                numTrain = 0;
                if isKey(configs,'numLabeledPerClass')
                    numTrain = length(configs.get('numLabeledPerClass'));
                else
                    sizes = getSizes(results,options.xAxisField);
                    numTrain = length(sizes);
                end
                if numTrain > 1
                    sizes = getSizes(results,options.xAxisField);
                    if isfield(options,'binPerformance') && options.binPerformance
                        if hasPostTM
                            measureVals{end+1} = getMeasurePerformanceForSize(results,options.numLabelsToUse,sizes);
                            measures = configs.get('postTransferMeasures');
                            dispName = TransferMeasure.GetDisplayName(measures{1},configs);
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
                elseif configs.has('numVecs') && length(configs.get('numVecs')) > 1
                    numVecs = configs.get('numVecs');
                    [index,leg] = plotTestResults(options,results,numVecs,colors,...
                                index,learnerName,leg);
                elseif configs.has('tau') && length(configs.get('tau')) > 1
                    tau = configs.get('tau');
                    [index,leg] = plotTestResults(options,results,tau,colors,...
                                index,learnerName,leg);
                else
                    error('What should we visualize?');
                end
            end
            if ~hasTestResults
                %display('visualizeResults.m: Hack for measure results - fix later');
                break;
            end
            %TODO: Find better way to do this loop
            if numel(learners) == 0 || numel(learners) < learnerIdx
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
    if options.showLegend && ~isempty(leg)
        legend(leg);
    end
    axisToUse = options.axisToUse;    
    if isfield(options,'showRepair') && options.showRepair        
        xAxisLabel = options.xAxisDisplay;
    elseif isfield(options,'binPerformance') && options.binPerformance
        xAxisLabel = 'Normalized Accuracy';                      
        axisToUse = [0 1 0 1];        
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

function [index,leg] = plotRelativePerformance(options,baselineFiles,results,sizes,configs,colors,index,learnerName,leg)
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
    leg{index} = ['Relative Acc: ' learnerName];
    index = index+1;
end

function [leg,index] = plotMeasureResults(options,configs,results,sizes,field,...
    resultField,displayName,learnerName,leg,index,colors)
    measureObj = configs.get(field);
    if ~isKey(options.measuresToShow,class(measureObj))
        return;
    end
    dispName = measureObj.getDisplayName();
    yVals = getMeans(results,resultField);
    yValsBars = getVariances(results,resultField);
    xVals = sizes;
    errorbar(xVals,yVals,yValsBars,'color',colors(index,:));
    leg{index} = [displayName ':' learnerName ':' dispName];
    index = index+1;
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
