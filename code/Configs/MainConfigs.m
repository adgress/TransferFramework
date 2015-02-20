classdef MainConfigs < Configs
    %Configs for an experiment
    
    properties
    end
    properties(Constant)
        isTrue = @(x) x;
        trueFunc = @(x) true;
        lengthGreaterThanOne = @(x) length(x) > 1;
        lengthGreaterThanZero = @(x) length(x) > 0;
        greaterThanZero = @(x) x > 0;
    end
    
    properties(Dependent)
        dataDirectory
        resultsDirectory        
    end
    
    methods               
        function [obj] = MainConfigs()
            obj = obj@Configs();
                        
            obj.configsStruct.measure=Measure();
            obj.configsStruct.learners=[];
            obj.configsStruct.dataDir='Data';
        end        
        function [v] = get.dataDirectory(obj)
            v = [obj.get('dataDir') '/' obj.get('dataName') '/'];
        end
        function [v] = get.resultsDirectory(obj)
            v = obj.getResultsDirectory();
        end
        
        function [v] = getResultsDirectory(obj)
            v = [getProjectDir() '/' obj.get('resultsDir') '/' ...
                 '/' obj.get('dataName') '/'];
        end
        
        
        function [s] = getDataFileName(obj)
            s = [obj.get('dataDir') '/' '/' obj.get('dataName') '/' ...
                obj.get('dataSet') '.mat'];
        end
        
        function [v] = getOutputDirectoryParams(obj)
            isTrue = MainConfigs.isTrue;
            trueFunc = MainConfigs.trueFunc;
            lengthGreaterThanOne = MainConfigs.lengthGreaterThanOne;
            lengthGreaterThanZero = MainConfigs.lengthGreaterThanZero;
            greaterThanZero = MainConfigs.greaterThanZero;
            v = {...                
                MainConfigs.OutputNameStruct('sourceNoise','sourceNoise',greaterThanZero,true)...
                MainConfigs.OutputNameStruct('useMeanSigma','',isTrue),...
                MainConfigs.OutputNameStruct('transferDataSetName','',trueFunc,true,false),...
                MainConfigs.OutputNameStruct('justKeptFeaturs','',isTrue),...
                MainConfigs.OutputNameStruct('numVecs','numVecsExp',lengthGreaterThanOne),...
                MainConfigs.OutputNameStruct('tau','tauExp',lengthGreaterThanOne),...
                MainConfigs.OutputNameStruct('clusterExp','cluster',isTrue),...                
                MainConfigs.OutputNameStruct('postTransferMeasures','TM',lengthGreaterThanZero),...                
            };
        %MainConfigs.OutputNameStruct('repairMethod','REP',trueFunc,true),...
        end        
        
        function [v] = getOutputFileNameParams(obj)
            isTrue = MainConfigs.isTrue;
            trueFunc = MainConfigs.trueFunc;
            lengthGreaterThanOne = MainConfigs.lengthGreaterThanOne;
            lengthGreaterThanZero = MainConfigs.lengthGreaterThanZero;
            
            v = {...
                MainConfigs.OutputNameStruct('postTransferMeasures','',lengthGreaterThanZero,true,false),...
                MainConfigs.OutputNameStruct('repairMethod','',trueFunc,true,false),...
                MainConfigs.OutputNameStruct('drMethod','',trueFunc,true,false),...
                MainConfigs.OutputNameStruct('transferMethodClass','',trueFunc,true,false),...
                MainConfigs.OutputNameStruct('learner','',lengthGreaterThanZero,true,false),...
            };
        end
        
        function [v] = stringifyFields(obj,paramArray,delim)
            v = '';
            for paramIdx=1:length(paramArray)
                params = paramArray{paramIdx};                
                if obj.has(params.configName) && ...
                    ( ~isa(params.shouldShowFunc,'function_handle')...
                    || params.shouldShowFunc(obj.get(params.configName)))
                    if ~isequal(v,'')
                        v = [v delim];
                    end
                    if params.shouldShowConfigName
                        configName = params.displayName;
                        v = [v configName];
                        if params.shouldShowValue
                            v = [v '='];
                        end
                    end
                    if params.shouldShowValue
                        value = obj.get(params.configName);
                        v = [v StringHelpers.ConvertToString(value)];
                    end
                end
            end
        end
        
        function [legendName] = makeLegendName(obj)
            
        end
        function [learnerConfigs] = makeDefaultLearnerConfigs(obj)
            learnerConfigs = LearnerConfigs();            
        end  
        
        function [] = setNGData(obj)
            obj.set('dataName','20news-bydate/splitData');
            obj.set('resultsDir','results_ng');
            obj.set('dataSet','CR2CR3CR42CR1');            
            obj.configsStruct.numSourcePerClass=Inf;
            obj.set('sourceDataSetToUse',{'CR4'});
        end
        
        function [] = setTommasiData(obj)
            obj.set('dataName','tommasi_data');
            obj.set('resultsDir','results_tommasi');
            obj.set('dataSet','tommasi_split_data');            
            obj.configsStruct.numSourcePerClass=Inf;
        end
        
        
        function [] = setCVData(obj)
            obj.configsStruct.numSourcePerClass=Inf;
            
            obj.configsStruct.dataName='CV-small';
            obj.configsStruct.dataDir='Data';
            obj.configsStruct.resultsDir='results';
            obj.configsStruct.transferDir='Data/transferData';
            obj.configsStruct.outputDir='results';
            obj.configsStruct.dataSet='ACW2D';
            obj.configsStruct.sourceDataSetToUse = {'W'};
        end
        function [] = setLLGCConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            obj.configsStruct.configLoader=ExperimentConfigLoader();
            llgcObj = LLGCMethod(learnerConfigs);
            obj.configsStruct.learners=llgcObj;
        end
        function [] = setLearnerLLGC(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            llgcObj = LLGCMethod(learnerConfigs);
            obj.configsStruct.learners=llgcObj;
        end
        function [] = setSepLLGCConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            %c = ProjectConfigs.Create();
            obj.configsStruct.configLoader=ExperimentConfigLoader(); 
            llgcObj = SepLLGCMethod(learnerConfigs);           	
            obj.configsStruct.learners=llgcObj;
        end   
    end   
    
    methods(Static)
        function [s] = OutputNameStruct(configName, displayName, ...
                shouldShowFunc,shouldShowValue,shouldShowConfigName)
            s = struct();
            s.configName = configName;        
            s.displayName = configName;
            s.shouldShowValue = false;
            s.shouldShowConfigName = true;
            s.shouldShowFunc = @(x) true;
            if exist('displayName','var') && ~isequal(displayName,'')
                s.displayName = displayName;
            end
            if exist('shouldShowFunc','var')
                s.shouldShowFunc = shouldShowFunc;
            end
            if exist('shouldShowValue','var')
                s.shouldShowValue = shouldShowValue;
            end
            if exist('shouldShowConfigName','var')
                s.shouldShowConfigName = shouldShowConfigName;
            end
            assert(s.shouldShowValue || s.shouldShowConfigName);
        end
    end
end