classdef LLGCMethod < HFMethod
    %LLGCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCMethod(configs)
            obj = obj@HFMethod(configs);
            if ~obj.has('useAlt')
                obj.set('useAlt',0);
            end
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
        
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC';
        end
        function [nameParams] = getNameParams(obj)
            %nameParams = {'sigma','sigmaScale','k','alpha'};            
            nameParams = {'sigmaScale'};
            if length(obj.get('alpha')) == 1
                nameParams{end+1} = 'alpha';
            end
            if obj.has('useAlt') && obj.get('useAlt')
                nameParams{end+1} = 'useAlt';
            end
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

