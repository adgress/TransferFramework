classdef ECTTransferMeasure < TransferMeasure
    %ECTTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ECTTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,metadata] = computeMeasure(obj,source,target,...
                options)
            sigma = obj.configs('sigma');
            if nargin >= 4 && isfield(options,'distanceMatrix')
                W = options.distanceMatrix.getRBFKernel(sigma);
            else                
                Xall = [source.X ; target.X];
                Y = [source.Y ; target.Y];
                type = [ones(numel(source.Y),1)*DistanceMatrix.TYPE_SOURCE ;...
                    ones(numel(target.Y),1)*DistanceMatrix.TYPE_TARGET_TRAIN];
                W = Kernel.RBFKernel(Xall,sigma);
                W = DistanceMatrix(W,Y,type);
            end
            D = diag(sum(W,2));
            %{
            K = double(W);
            min(K(:))
            max(K(K(:) < 1))
            %}
            L = D - W;
            isD = inv(D).^.5;
            NL = isD*L*isD;
            invL = pinv(L);
            Wmat = double(W);
            volG = sum(Wmat(:));
            ECT = volG*Kernel.ComputeKernelDistance(invL);
            
            T2L = ECT(W.isTarget(),W.isLabeled());
            minT2L = min(T2L,[],2);
            T2LT = ECT(W.isTarget(),W.isLabeledTarget());
            minT2LT = min(T2LT,[],2);
            
            val = mean(minT2LT)/mean(minT2L);
            obj.displayMeasure(val);
            metadata = struct();
        end
        function [name] = getPrefix(obj)
            name = 'ECT';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'sigma'};
        end
    end
    
end

