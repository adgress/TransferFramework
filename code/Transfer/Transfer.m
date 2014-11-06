classdef Transfer < Saveable
    %TRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        
    end
    properties
    end
    
    methods
        function obj = Transfer(configs)
            if nargin < 1
                configs = [];
            end
            obj = obj@Saveable(configs);
        end
        
        function [transformedTargetTrain,transformedTargetTest,...
                tSource,tTarget] = ...
                performTransfer(obj,targetTrainData, targetTestData,...
                sourceDataSets)
            transformedTargetTrain = targetTrainData;            
            transformedTargetTest = targetTestData;
            %assert(numel(sourceDataSets) == 1);
            tSource = sourceDataSets;
            type = [DataSet.TargetTrainType(targetTrainData.size());...
                DataSet.TargetTestType(targetTestData.size())];
            tTarget = DataSet('','','',[targetTrainData.X;targetTestData.X],...
                [targetTrainData.Y;-1*ones(numel(targetTestData.Y),1)],type);
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
        function [prefix] = getPrefix(obj)
            prefix = 'TO';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        function [d] = getDirectory(obj)            
            d='';
        end
    end
    
end

