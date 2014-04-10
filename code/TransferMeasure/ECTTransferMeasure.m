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
            %invL = pinvs(L);
            invL = inv(L + 1/size(L,1)) - 1/size(L,1);
            Wmat = double(W);
            volG = sum(Wmat(:));
            ECT = volG*Kernel.ComputeKernelDistance(invL);
            
            useUnlabeled = 0;
            if useUnlabeled
                T2L = ECT(W.isTarget(),W.isLabeled());
                minT2L = min(T2L,[],2);
                T2LT = ECT(W.isTarget(),W.isLabeledTarget());
                minT2LT = min(T2LT,[],2);            
                val = mean(minT2LT)/mean(minT2L);            
            else
                labeledTargetY = W.Y(W.isLabeledTarget());
                labeledY = W.Y(W.isLabeled());
                
                LT2L = ECT(W.isLabeledTarget(),W.isLabeled());
                l1 = repmat(labeledTargetY,1,size(LT2L,2)) ;
                l2 = repmat(labeledY',size(LT2L,1),1); 
                LT2L(l1 ~= l2) = Inf;
                minLT2L = sort(LT2L,2);
                
                LT2LT = ECT(W.isLabeledTarget(),W.isLabeledTarget());
                l1 = repmat(labeledTargetY',size(LT2LT,1),1);
                LT2LT(l1 ~= l1') = Inf;
                minLT2LT = sort(LT2LT,2);
                val = mean(minLT2LT(:,2))/mean(minLT2L(:,2));
            end
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

