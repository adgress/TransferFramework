classdef MainConfigs < Configs
    %CONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    properties(Constant)
        isTrue = @(x) x;
        trueFunc = @(x) true;
        lengthGreaterThanOne = @(x) length(x) > 1;
        lengthGreaterThanZero = @(x) length(x) > 0;
    end
    
    properties(Dependent)
        dataDirectory
        resultsDirectory        
    end
    
    methods               
        function [obj] = MainConfigs()
            obj = obj@Configs();
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
        
        function [v] = getOutputDirectoryParams(obj)
            isTrue = MainConfigs.isTrue;
            trueFunc = MainConfigs.trueFunc;
            lengthGreaterThanOne = MainConfigs.lengthGreaterThanOne;
            lengthGreaterThanZero = MainConfigs.lengthGreaterThanZero;
            v = {...
                MainConfigs.OutputNameStruct('useMeanSigma','',isTrue),...
                MainConfigs.OutputNameStruct('dataSet','',trueFunc,true,false),...
                MainConfigs.OutputNameStruct('justKeptFeaturs','',isTrue),...
                MainConfigs.OutputNameStruct('numVecs','numVecsExp',lengthGreaterThanOne),...
                MainConfigs.OutputNameStruct('tau','tauExp',lengthGreaterThanOne),...
                MainConfigs.OutputNameStruct('clusterExp','cluster',isTrue),...
                MainConfigs.OutputNameStruct('repairMethod','REP',trueFunc,true),...
                MainConfigs.OutputNameStruct('postTransferMeasures','TM',lengthGreaterThanZero)...
            };
        end        
        
        function [v] = getOutputFileNameParams(obj)
            isTrue = MainConfigs.isTrue;
            trueFunc = MainConfigs.trueFunc;
            lengthGreaterThanOne = MainConfigs.lengthGreaterThanOne;
            lengthGreaterThanZero = MainConfigs.lengthGreaterThanZero;
            
            v = {...
                MainConfigs.OutputNameStruct('postTransferMeasures','',lengthGreaterThanZero,true,false),...
                MainConfigs.OutputNameStruct('repaireMethod','',trueFunc,true,false),...
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