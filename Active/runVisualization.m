function [] = runVisualization()
    setPaths;
    %close all    
    if ProjectConfigs.data ~= Constants.ALL_DATA
        vizConfigs = ProjectConfigs.VisualizationConfigs();    
    end
    if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE_TRANSFER
        error('do we want this?');
        switch ProjectConfigs.data
            case Constants.CV_DATA
                domainsToViz = ProjectConfigs.cvDomainsToViz;
            case Constants.TOMMASI_DATA
                domainsToViz = ProjectConfigs.tommasiDomainsToViz;
            case Constants.NG_DATA
                domainsToViz = ProjectConfigs.ngDomainsToViz;            
            case Constants.HOUSING_DATA
            case Constants.YEAST_BINARY_DATA
            case Constants.USPS_DATA
            otherwise
                error('unknown data set');
        end
    end
    if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
        domainsToViz = {};
        ngDomains = {'CR1','CR2','CR3','CR4'};
        tommasiDomains = {'10  15','10  23','23  25'};
        uspsDomains = {'3  8','1  7'};
        configIndex = 1;
        dataSets = ProjectConfigs.data;
        numRows = 4;
        numCols = 2;
        switch ProjectConfigs.data
            case Constants.NG_DATA
                domainsToViz = ngDomains;
            case Constants.TOMMASI_DATA
                domainsToViz = tommasiDomains;
            case Constants.HOUSING_DATA                
            case Constants.YEAST_BINARY_DATA
            case Constants.USPS_DATA
                domainsToViz = uspsDomains;
            case Constants.ALL_DATA
                vizNG = ProjectConfigs.VisualizationConfigs(Constants.NG_DATA);                
                vizUSPS = ProjectConfigs.VisualizationConfigs(Constants.USPS_DATA);
                vizHousing = ProjectConfigs.VisualizationConfigs(Constants.HOUSING_DATA);
                vizYeast = ProjectConfigs.VisualizationConfigs(Constants.YEAST_BINARY_DATA);
                domainsToViz = {ngDomains{:} , uspsDomains{:},[],[]};
                vizConfigs = {vizNG,vizUSPS,vizHousing,vizYeast};
                configIndex = [1 1 1 1 2 2 3 4];
                domainsToViz = reshape(domainsToViz,numRows,numCols);
                configIndex = reshape(configIndex,numRows,numCols);
                dataSets = [Constants.NG_DATA Constants.USPS_DATA ...
                    Constants.HOUSING_DATA Constants.YEAST_BINARY_DATA];
                dataSetNames = {'20NG','USPS','Housing','Yeast'};
            otherwise
                error('unknown data set');
        end
        
    end    
    if ~iscell(vizConfigs)
        vizConfigs = {vizConfigs};
    end
    width = 1800;
    height = 500;
    usePaperSettings = ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE;
    if usePaperSettings
        %For 2 x 4 plots
        %{
        width = 600;
        height = 400;
        %}
        width = 400;
        height = 600;
        for idx=1:length(vizConfigs)
            currConfigs = vizConfigs{idx};
            currConfigs.set('showLegend',false);
            %currConfigs.set('showLegend',idx == 1);
            currConfigs.set('axisToUse',[-1 21 0 1.1]);
            currConfigs.set('autoAdjustXAxis',false);
            currConfigs.set('autoAdjustYAxis',false);
            currConfigs.set('showXAxisLabel',false);
        end
        rowNameWidth = 190;
        showNumIterations = false;
        cellWidth = 50;
    end    
    if ProjectConfigs.createTable
        width = 1000;
        height = 500;
    end
    f = figure('position',[500 200 width height]);
    plotTermination = ProjectConfigs.plotTerminationCriterion;
    plotTerminationError = ProjectConfigs.plotTerminationCriterionError;
    plotTerminationCriterionDelta = ProjectConfigs.plotTerminationCriterionDelta;
    if ProjectConfigs.createTable
        set(gca,'Visible','off');
        [numRows,numCols] = size(domainsToViz);
        if plotTermination
            colNames = {};
            rowNames = {};
            desiredPerf = ProjectConfigs.desiredPerf;
            for idx=1:length(desiredPerf)
                colNames{idx} = num2str(desiredPerf(idx));
            end
            correctFields = {'terminatedPerf','numIterations'};
            learnerFileNames = {'LogReg'};
            %learnerFileNames = {'SVML2'};
            %learnerFileNames = {'NaiveBayes'};
            learnerNames = {'Logistic Regression'};
            data = cell(numel(domainsToViz)*length(learnerFileNames),...
                length(desiredPerf));
            rowIdx = 1;
        elseif plotTerminationError || plotTerminationCriterionDelta
            colNames = {};
            rowNames = {};
            
            if plotTerminationError
                %desiredPerf = ProjectConfigs.desiredPerf;
                desiredPerf = ProjectConfigs.iterationDelta;
                correctFields = {'terminatedPerfError','numIterations'};
            else
                desiredPerf = ProjectConfigs.iterationDelta;
                correctFields = {'terminatedPerfCVDelta','numIterations'};
            end
            for idx=1:length(desiredPerf)
                colNames{idx} = num2str(desiredPerf(idx));
            end            
            learnerFileNames = {};
            learnerNames = {};
            learnerFileNames{end+1} = 'LogReg';
            learnerNames{end+1} = 'Logistic Regression';
            learnerFileNames{end+1} = 'SVML2';
            learnerNames{end+1} = 'SVM';
            learnerFileNames{end+1} = 'NaiveBayes';
            learnerNames{end+1} = 'Naive Bayes';
            data = cell(numel(domainsToViz)*length(learnerFileNames),...
                length(desiredPerf));
            rowIdx = 1;
        else
            correctFields = {'preTransferValTest'};
            colNames = {};
            rowNames = {'L2 Regularized Logistic Regression',...
                'L2 Regularized SVM', 'Naive Bayes'};
            idxToUse = 21;
            learnerFileNames = {'LogReg','SVML2','NaiveBayes'};
            data = cell(length(learnerFileNames),numel(domainsToViz));
        end                                
        precision = 2;
        resultStructs = cell(numRows,numCols);        
        for idx=1:length(learnerFileNames)
            dataSetIdx = 1;
            for row=1:numRows
                for col=1:numCols                
                    index = configIndex(1,1);
                    if ~isscalar(configIndex)
                        index = configIndex(row,col);
                    end
                    currDomainToViz = domainsToViz{row,col};
                    currVizConfigs = vizConfigs{index};
                    [plotConfigs,~,~] = ProjectConfigs.makePlotConfigs(learnerFileNames{idx});
                    currVizConfigs.set('plotConfigs',plotConfigs);
                    %plotConfigs = currVizConfigs.get('plotConfigs');                
                    assert(length(plotConfigs) == length(correctFields));                                   
                    for fieldIdx=1:length(plotConfigs)
                        field = plotConfigs{fieldIdx}.get('fieldToPlot');
                        assert(isequal(correctFields{fieldIdx},field));
                    end
                    if ~isempty(currDomainToViz)
                        [d] = ProjectConfigs.getResultsDirectory(dataSets(index));
                        newResultsDir = [d '/' domainsToViz{row,col} '/'];
                    end
                    currVizConfigs.set('resultsDirectory',newResultsDir);
                    name = dataSetNames{index};
                    if ~isempty(currDomainToViz)
                        name = [name ': ' currDomainToViz];
                    end
                    
                    [~,resultStructs{row,col}] = visualizeResults(currVizConfigs,f);                
                    
                    if plotTermination || plotTerminationError || plotTerminationCriterionDelta
                        d = resultStructs{row,col}.displayVals;
                        rowNames{end+1} = [learnerNames{idx} ' ' name];
                        for perfIdx = 1:length(desiredPerf)
                            m1 = d{1}.means(perfIdx);
                            v1 = d{1}.vars(perfIdx);                            
                            m2 = d{2}.means(perfIdx);
                            v2 = d{2}.vars(perfIdx);
                            if showNumIterations
                                s = [num2str(m1,precision) ' : ' num2str(m2,precision)];
                            else
                                s = num2str(m1,precision);
                            end
                            data{rowIdx,perfIdx} = s;
                        end
                        rowIdx = rowIdx + 1;
                    else
                        if idx==1
                            colNames{end+1} = name;
                        end
                        m = resultStructs{row,col}.displayVals{1}.means(idxToUse);
                        v = resultStructs{row,col}.displayVals{1}.vars(idxToUse);                        
                        s = [num2str(m,precision) ' ' setstr(177) ' ' num2str(v,precision)];
                        data{idx,dataSetIdx} = s;
                        dataSetIdx = dataSetIdx + 1;
                    end
                end
            end
        end
        table = uitable(f,'ColumnName',colNames,'RowName',rowNames,...
            'data', data);        
        
        widths = {};
        for idx=1:length(colNames)
            widths{end+1} = cellWidth;
        end
        set(table,'ColumnWidth',widths);
        settablewidth(table,rowNameWidth)
        extent = get(table,'Extent');
        
        set(table,'Position',extent);
        centertabletext(table);
        set(f,'Position',[500 500 extent(3) extent(4)]);
    else        
        [numRows,numCols] = size(domainsToViz);
        %for 2 x 4 plot
        %figureHandles = tight_subplot(numRows,numCols,.1,.1,.1);
        figureHandles = tight_subplot(numRows,numCols,.1,.08,.12);
        if ~isempty(domainsToViz) && ProjectConfigs.useDomainsToViz
            figIdx = 1;
            for row = 1:size(domainsToViz,1)
                for col=1:size(domainsToViz,2)
                    %subplot(1,length(domainsToViz),i);
                    f = figureHandles(figIdx);
                    axes(f);
                    set(f,'XTickLabelMode','auto');
                    set(f,'YTickLabelMode','auto');
                    index = configIndex(1,1);
                    if ~isscalar(configIndex)
                        index = configIndex(row,col);
                    end
                    currDomainToViz = domainsToViz{row,col};
                    currVizConfigs = vizConfigs{index};     
                    %Only show & axis label for first subplot       
                    currVizConfigs.set('showYAxisLabel',col == 1);
                    if ~isempty(currDomainToViz)
                        [d] = ProjectConfigs.getResultsDirectory(dataSets(index));
                        newResultsDir = [d '/' domainsToViz{row,col} '/'];
                    end
                    currVizConfigs.set('resultsDirectory',newResultsDir);
                    name = dataSetNames{index};
                    if ~isempty(currDomainToViz)
                        name = [name ': ' currDomainToViz];                    
                    end
                    title(name);
                    [~,returnStruct] = visualizeResults(currVizConfigs,f);

                    figIdx = figIdx + 1;
                end
            end
            parent = get(f,'parent');
            a = axes('Position',[0 0 1 1],'Visible','off');
            text(.5,.03,'Active Learning Iterations','HorizontalAlignment','center');
            %learner = 'Naive Bayes';
            learner = 'LogReg';
            text(.5,.98,learner,'HorizontalAlignment','center');
        else
            [~,returnStruct] = visualizeResults(vizConfigs,f);            
        end   
    end
end