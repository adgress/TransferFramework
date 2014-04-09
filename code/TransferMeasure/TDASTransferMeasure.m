classdef TDASTransferMeasure < TransferMeasure
    %TDASMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TDASTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,metadata] = computeMeasure(obj,source,target,options)            
            autoEps = obj.configs('autoEps');
            numSource = size(source.X,1);
            numTarget = size(target.X,1);
            %Dst = pdist2(target.X,source.X,'euclidean');
            Dst = pdist2(source.X,target.X,'euclidean');
            minDst = min(Dst,[],2);
            switch autoEps
                case 0
                    eps = obj.configs('epsilon');
                case 1                    
                    eps = mean(minDst);   
                case 2
                    eps = median(minDst);
                otherwise
                    error('');
            end
            numWithinEps = sum(Dst < eps,2);
            %assert(size(numWithinEps,1) == size(target.Y,1));
            val = mean(numWithinEps)/size(Dst,2);            
            obj.displayMeasure(val);
            metadata = {};
        end
                     
        function [name] = getPrefix(obj)
            name = 'TDAS';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'autoEps'};
        end
    end
    
end

