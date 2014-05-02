classdef Transfer
    %TRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        
    end
    
    methods
        function obj = Transfer()            
        end
        
        function [transformedTargetTrain,transformedTargetTest,metadata,...
                tSource,tTarget] = ...
                performTransfer(obj,targetTrainData, targetTestData,...
                sourceDataSets,validateData,configs,savedData)
            transformedTargetTrain = targetTrainData;            
            transformedTargetTest = targetTestData;
            tSource = sourceDataSets{1};
            tTarget = DataSet('','','',[targetTrainData.X;targetTestData.X],...
                [targetTrainData.Y;-1*ones(numel(targetTestData.Y),1)]);
            metadata = struct();
        end           
        
        function [name] = getResultFileName(obj,configs)
            name = obj.getMethodName(configs);
        end
        
        function [name] = getMethodName(obj,configs,delim)
            if nargin < 3
                delim = '_';                
            end
            objectClass = str2func(class(obj));
            name = eval([class(obj) '.getPrefix();']);
            
            transferObject = objectClass();
            params = transferObject.getNameParams();
            
            for i=1:numel(params)
                n = params{i};
                v = configs(n);
                if ~isa(v,'char')
                    v = num2str(v);
                end
                name = [name delim n '=' v];
            end
        end
        
        function [transferName] = getDisplayName(obj,configs)
            transferName = obj.getMethodName(configs,',');
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        
        function [transferData] = loadTransferData(obj,configs)
            transferFile = configs('transferFile');
            transferData = struct();
            if exist(transferFile,'file')
                load(transferFile);
            end
        end
        function [isSame] = areConfigsIdentical(obj,configs1,configs2)
            isSame = true;
            for str=obj.parameters
                key = str{1};
                if ~isKey(configs1,key) || ~isKey(configs2,key)
                    isSame = false;
                    break;
                end
                val1 = configs1(key);
                val2 = configs2(key);
                if ~isequal(val1,val2)
                    isSame = false;
                    break;
                end
            end            
        end
        
    end
    methods(Static)
        function [name] = GetName(transferClassName,configs)        
            transferClass = str2func(transferClassName);
            transferObject = transferClass();
            name = transferObject.getDisplayName(configs);
        end
        function [name] = GetPrefixForMethod(transferClass,configs)
            name = eval([transferClass '.getPrefix()']);
        end
        function [name] = MethodName(configs)            
            name = 'Target Only';
        end
        function [prefix] = getPrefix()
            prefix = 'TO';
        end
    end
    
end

