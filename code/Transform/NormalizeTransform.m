classdef NormalizeTransform < TransformBase
    %STANDARDIZETRANSFORM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mean
        stdevs
    end
    
    methods
        function [obj] = NormalizeTransform(configs)
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@TransformBase(configs);
        end
        
        function [] = learn(obj,X,Y)
            [~,obj.mean,obj.stdevs] = zscore(X);
            I = isnan(obj.mean) | isinf(obj.mean);
            assert(~any(I));
            I = isnan(obj.stdevs) | isinf(obj.stdevs);
            assert(~any(I));
            I = obj.stdevs == 0;
            if any(I)
                display('NormalizeTransform: 0 stdev - replacing with 1');
                obj.stdevs(I) = 1;
            end
        end
        
        function [Z] = apply(obj,X,Y)
            Z = X - repmat(obj.mean,size(X,1),1);
            Z = Z ./ repmat(obj.stdevs,size(X,1),1);
            Z(isnan(Z(:))) = 0;
            %diff = Z - obj.Z;
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'ZScore';
        end        
    end
    
end

