classdef TransformBase < Saveable
    %TRANSFORMBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function [obj] = TransformBase(configs)            
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@Saveable(configs);
        end
        
        function [] = learn(obj,X,Y)            
        end
        
        function [Z] = apply(obj,X,Y)
            Z = X;            
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'Identity';
        end  
        
        function [d] = getDirectory(obj)
            error('');
        end                
        
        function [nameParams] = getNameParams(obj)
            error('TODO');
        end
    end
    
end

