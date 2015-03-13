classdef FisherScoreTransform < TransformBase
    %FISHERSCORETRANSFORM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = NormalizeTransform(configs)
            error('TODO');
            if ~exist('configs','var')
                configs = Configs();
            end
            obj.configs = configs;
        end
        function [] = learn(obj,X,Y)
            [obj.Z,obj.mean,obj.stdevs] = zscore(X);
        end
        
        function [Z] = apply(obj,X,Y)
            Z = X - repmat(obj.mean,size(X,1),1);
            Z = Z ./ repmat(obj.stdevs,size(X,1),1);
            %diff = Z - obj.Z;
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'FisherScore';
        end 
    end
    
end

