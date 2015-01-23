classdef LLGCMethod < HFMethod
    %LLGCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCMethod(configs)
            obj = obj@HFMethod(configs);
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            useHF = false;
            if exist('savedData','var')
                [testResults,savedData] = ...
                    obj.trainAndTestGraphMethod(input,useHF,savedData);
            else
                [testResults] = ...
                    obj.trainAndTestGraphMethod(input,useHF);
            end
        end
        function [] = updateConfigs(obj, newConfigs)
            %keys = {'sigma', 'sigmaScale','k','alpha'};
            keys = {'sigmaScale','alpha'};
            obj.updateConfigsWithKeys(newConfigs,keys);
        end                
        
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC';
        end
        function [nameParams] = getNameParams(obj)
            %nameParams = {'sigma','sigmaScale','k','alpha'};
            nameParams = {'sigmaScale','alpha'};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

