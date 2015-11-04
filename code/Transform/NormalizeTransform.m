classdef NormalizeTransform < TransformBase
    %STANDARDIZETRANSFORM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        meanX
        stdevs
        meanY
    end
    
    methods
        function [obj] = NormalizeTransform(configs)
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@TransformBase(configs);
        end
        
        function [] = learn(obj,X,Y)
            [~,obj.meanX,obj.stdevs] = zscore(X);
            I = isnan(obj.meanX) | isinf(obj.meanX);
            assert(~any(I));
            I = isnan(obj.stdevs) | isinf(obj.stdevs);
            assert(~any(I));
            I = obj.stdevs == 0;
            if any(I)
                display('NormalizeTransform: 0 stdev - replacing with 1');
                obj.stdevs(I) = 1;
            end
            if exist('Y','var') && ~isempty(Y)
                obj.meanY = mean(Y);
            end
        end
        
        function [Z,Y] = apply(obj,X,Y)
            Z = X - repmat(obj.meanX,size(X,1),1);
            Z = Z ./ repmat(obj.stdevs,size(X,1),1);
            Z(isnan(Z(:))) = 0;
            %diff = Z - obj.Z;
            if exist('Y','var') && ~isempty(Y)
                Y = Y - obj.meanY;
            end
        end
        
        function [Y] = invert(obj,Y)
            Y = Y + obj.meanY;
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'ZScore';
        end        
    end
    
end

