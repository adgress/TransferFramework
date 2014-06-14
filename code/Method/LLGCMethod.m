classdef LLGCMethod < HFMethod
    %LLGCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCMethod(configs)
            obj = obj@HFMethod(configs);
        end
        
        function [testResults,metadata,savedData] = ...
                trainAndTest(obj,input,savedData)
            useHF = false;
            if exist('savedData','var')
                [testResults,metadata,savedData] = ...
                    trainAndTestGraphMethod(obj,input,useHF,savedData);
            else
                [testResults,metadata] = ...
                    trainAndTestGraphMethod(obj,input,useHF);
            end
        end
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

