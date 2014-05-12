classdef LLGCTransferRepair < TransferRepair       
    properties
        configs
    end
    
    methods
        function obj = LLGCTransferRepair(configs)
            obj.configs = configs;                        
        end        
        
        function [repairedInput] = ...
                repairTransfer(obj,input,targetScores)
            percToRemove = obj.configs('percToRemove');
            
                         
            repairedInput = input;
            strategy = obj.configs('strategy');
            if isequal(strategy,'Random')
                isSource = find(input.train.type == Constants.SOURCE);
                numSource = length(isSource);
                toRemove = randperm(numSource,floor(percToRemove*numSource));                
                repairedInput.train.remove(isSource(toRemove));
            elseif isequal(strategy,'PruneIncorrect')
                dataSet = DataSet.Combine(input.train,train.test);
                dataSet.removeTestLabels();
                
            else
                error(['Unknown Strategy: ' strategy]);
            end
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC';
        end        
        function [nameParams] = getNameParams(obj)
            nameParams = {'strategy','percToRemove','numIterations'};
        end
    end
    
    
end

