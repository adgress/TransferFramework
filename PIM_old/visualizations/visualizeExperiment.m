function [f] = visualizeExperiment(experiment,options,indicesToUse)
    loadConstants();   
    if nargin < 2
        error('');
    end
    if nargin < 3
        numMethods = numel(experiment.settings.methodSettings);
        indicesToUse = 1:numMethods;
    else
        numMethods = numel(indicesToUse);
    end
    if options.measure == MEAN_PRECISION
        accStr = 'Mean Precision';
    elseif options.measure == MEAN_RECALL
        accStr = 'Mean Recall';
    elseif options.measure == OVERALL_PRECISION
        accStr = 'Overall Precision';
    elseif options.measure == OVERALL_RECALL
        accStr = 'Overall Recall';
    elseif options.measure == DYNAMIC_PRECISION
        accStr = 'Dynamic Precision';
    elseif options.measure == MEAN_F1
        accStr = 'Mean F1 Score';
    elseif options.measure == MEAN_MCC
        accStr = 'Mean MCC';
    else
        error('Unknown measure');
    end
    settingsStr = createSettingsString(experiment);    
    if isfield(experiment,'sizes')
        titleStr = ['Training Set Size vs ' accStr ' ' settingsStr];
        xStr = 'Training Set Size (Percentage of entire data set)';
    elseif isfield(experiment,'numTags')
        titleStr = ['Number of Tags vs ' accStr ' ' settingsStr];
        xStr = sprintf('Number of Tags',experiment.settings.percentTrain);
    elseif isfield(experiment,'numVectors')
        titleStr = ['Number of Vectors vs ' accStr ' ' settingsStr];
        xStr = sprintf('Number of Vectors',experiment.settings.percentTrain);
    end   
    
    hold on;
    index = 1;
    if options.method == 0
        for i=indicesToUse
            subplot(1,numMethods,index);
            colorMap = hsv(numel(experiment.settings.kNN));
            plotNames = visualizeExperimentAtIndex(experiment,i,options,colorMap);
            legend(plotNames);
            index = index+1;
        end
    else
        experiment.settings.kNN = options.kNN;
        numK = numel(experiment.settings.kNN);
        if options.measure == DYNAMIC_PRECISION
            numK = 1;
        end              
        if options.useSubplots
            f = figure('Position',[100 100,450,450]);
        end
        for i=1:numK
            if options.useSubplots
                subplot(1,numK,i);
            else
                f = figure('Position',[100, 100,450,350]);
            end
            if i==1 || ~options.useSubplots
                ylabel(accStr);
                xlabel(xStr);
            end
            if isfield(experiment,'sizes')
                xlim([0 .6]);
            end
            if isfield(experiment,'numVectors')
                xlim([0,40]);
            end
            visualizeExperimentForK(experiment,i,options)
            set(gca,'FontSize',10);
            if ~options.useSubplots
                set(gcf,'PaperPositionMode','auto')
                fileName = [options.prefix '-' 'k=' num2str(options.kNN(i))];
                print(f,'-djpeg',['figures/' fileName '.jpg']);
                saveas(f,['figures/' fileName '.fig']); 
            end
        end
    end
    %{
    text(-.5, options.ymax+.005,titleStr,'HorizontalAlignment' ...
            ,'left','VerticalAlignment', 'bottom')
    text(-.5, options.ymin-.005,xStr,'HorizontalAlignment' ...
            ,'left','VerticalAlignment', 'top')
    %}
    hold off;
end

function [] = visualizeExperimentForK(experiment,kIndex,options)   
    loadConstants;
    numMethods = numel(experiment.settings.methodSettings);
    expCopy = experiment;
    optionsCopy = options;
    optionsCopy.ymin = optionsCopy.ymin(kIndex);
    optionsCopy.ymax = optionsCopy.ymax(kIndex);
    title(sprintf('K = %d',experiment.settings.kNN(kIndex)));    
    %{
    for i=1:numel(expCopy.trainAcc)
        for j=1:numMethods
            expCopy.trainAcc{i}{j} = expCopy.trainAcc{i}{j}(kIndex,:);
            expCopy.testAcc{i}{j} = expCopy.testAcc{i}{j}(kIndex,:);
        end
    end
    %}
    if optionsCopy.measure > 0
        optionsCopy.k = experiment.settings.kNN(kIndex);
        [expCopy.trainAcc,expCopy.testAcc] = computeMeasure(expCopy,optionsCopy);        
    end
    
    expCopy.settings.kNN = expCopy.settings.kNN(kIndex);
    plotNames = {};
    colorMap = hsv(numMethods);
    for i=1:numMethods
        if ~options.showGuess && experiment.settings.methodSettings{i}.method == GUESS
            continue;
        end
        visualizeExperimentAtIndex(expCopy,i,optionsCopy,colorMap(i,:));        
        plotNames{i} = experiment.settings.methodSettings{i}.name;
    end
    if kIndex == 1
        legend(plotNames);
    end
end

function [trainMeasure,testMeasure] = computeMeasure(experiment,options)
    NNData = {experiment.trainNNData,experiment.testNNData};
    measureData = {};
    for i=2:-1:1
        currNNData = NNData{i};
        newData = {};
        for j=1:numel(currNNData)
            d = currNNData{j};
            newD = {};
            totalNonZero = zeros(numel(d),1);
            for k=1:numel(d)
                dd = d{k};
                if j == 1 && i == 2 && k == 4
                    display('');
                end
                newDD = zeros(1,numel(dd));                
                for l=1:numel(dd)
                    ddd = dd(l);
                    [newDD(l),numNonZero] = ...
                        computeMeasureForData(ddd,options);
                    totalNonZero(k) = totalNonZero(k) + numNonZero;
                end
                totalNonZero(k) = totalNonZero(k) ./ numel(dd);
                newD{k} = newDD;
            end            
            if i==2
                totalNonZero'
            end
            newData{j} = newD;
        end
        measureData{i} =  newData;
    end
    trainMeasure = measureData{1};
    testMeasure = measureData{2};
end

function [m,numNonZero] = computeMeasureForData(data,options)
    loadConstants();
    answers = data.answers;
    predictedNN = data.nn;
    numData = size(predictedNN,1);
    numLabels = size(predictedNN,2);
    labelMeasures = zeros(1,numLabels);
    
    k = options.k;
    TP = labelMeasures;
    TN = labelMeasures;
    FP = labelMeasures;
    FN = labelMeasures;
    for i=1:numData
        currNN = predictedNN(i,:);
        currAnswers = answers(i,:);
        %minLabels = min([k sum(currAnswers)]);
        minLabels = k;
        if options.measure == DYNAMIC_PRECISION
            minLabels = sum(currAnswers);
        end
        predCurrNN = currNN(1:minLabels);
        otherCurrNN = currNN(minLabels+1:end);
        TP(predCurrNN) = TP(predCurrNN) + currAnswers(predCurrNN);
        FP(predCurrNN) = FP(predCurrNN) + (1 - currAnswers(predCurrNN));
        TN(otherCurrNN) = TN(otherCurrNN) + (1 - currAnswers(otherCurrNN));
        FN(otherCurrNN) = FN(otherCurrNN) + currAnswers(otherCurrNN);
    end
    
    overallPrecision = sum(TP)/(sum(TP)+sum(FP));
    overallRecall = sum(TP)/(sum(TP)+sum(FN));
    precision = TP./(TP + FP);
    recall = TP./(TP + FN);    
    precision(isnan(precision)) = 0;
    recall(isnan(recall)) = 0;
    meanPrecision = sum(precision) / numLabels;
    meanRecall = sum(recall) / numLabels;
    
    overallAccuracy = sum(TP+TN)/sum(TP+TN+FP+FN);
    accuracy = (TP + TN)./(TP+TN+FP+FN);
    meanAccuracy = mean(accuracy);
    overallF1Score = 2*overallPrecision*overallRecall/((overallPrecision+overallRecall));
    f1Scores = 2*(precision.*recall)./((precision + recall));    
    matthewsCC = (TP.*TN - FP.*FN)./...
        sqrt((TP+FP).*(TP + FN).*(TN+FP).*(FN+FN));
    matthewsCC(isnan(matthewsCC)) = 0;
    matthewsCC(isinf(matthewsCC)) = 0;
    %Note: Only considering non-nan f1Scores
    f1Scores(isnan(f1Scores)) = 0;    
    meanF1Score = mean(f1Scores);
    if options.measure == MEAN_PRECISION
        m = meanPrecision;
        numNonZero = sum(precision > 0);
    elseif options.measure == MEAN_RECALL        
        numNonZero = sum(recall > 0);
        m = meanRecall;
    elseif options.measure == OVERALL_PRECISION
        numNonZero = 0;
        m = overallPrecision;        
    elseif options.measure == OVERALL_RECALL
        numNonZero = 0;
        m = overallRecall;
    elseif options.measure == DYNAMIC_PRECISION
        m = meanPrecision;
    elseif options.measure == MEAN_F1
        m = meanF1Score;
        numNonZero = sum(f1Scores > 0);
    elseif options.measure == MEAN_MCC
        m = mean(matthewsCC);
        numNonZero = sum(matthewsCC > 0);
    else
        error('Unknown measure');
    end
end

function [plotNames] = visualizeExperimentAtIndex(experiment,index,options,colorMap)
    numRuns = numel(experiment.trainAcc);
    k = numel(experiment.settings.kNN);
    meanTrainAcc = zeros(k,numRuns);
    meanTestAcc = zeros(k,numRuns);
    trainAccVar = zeros(k,numRuns);
    testAccVar = zeros(k,numRuns);
    for i=1:numRuns
        trainAcc = experiment.trainAcc{i}{index};
        testAcc = experiment.testAcc{i}{index};
        meanTrainAcc(:,i) = mean(trainAcc,2);
        meanTestAcc(:,i) = mean(testAcc,2);
        trainAccVar(:,i) = var(trainAcc,[],2)';
        testAccVar(:,i) = var(testAcc,[],2)';
    end    
       
    if isfield(experiment,'sizes')
        xVal = experiment.sizes;        
    elseif isfield(experiment,'numTags')
        xVal = experiment.numTags;        
    elseif isfield(experiment,'numVectors')
        xVal = experiment.numVectors;
    end        
    %ylim([options.ymin,options.ymax]);
    plotNames1 = {};
    if options.showTrainingError
        plotNames1 = plotData(xVal,meanTrainAcc,trainAccVar,experiment.settings.kNN,colorMap);    
    end
    plotNames2 = plotData(xVal,meanTestAcc,testAccVar,experiment.settings.kNN,colorMap);    
    plotNames = [plotNames1 plotNames2];
end

function [plotNames] = plotData(xVal,yVal,variance,kNN,colorMap)    
    plotNames = cell(numel(kNN),1);  
    hold on;
    index = 1;
    for i=kNN        
        errorbar(xVal,yVal(index,:),variance(index,:),'color',colorMap(index,:));
        plotNames{index} = sprintf('T = %d',i);
        index = index+1;
    end    
end