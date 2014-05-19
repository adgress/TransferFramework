classdef Kernel < handle
    %KERNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        K
    end
    
    methods
        function obj = Kernel(W)
            obj.K = W;
        end
    end
    
    methods(Static)
        function [K] = swapElements(K,i,j)
            Ki = K(i,:);
            Kj = K(j,:);
            K(i,:) = Kj;
            K(j,:) = Ki;
            K_i = K(:,i);
            K_j = K(:,j);
            K(:,i) = K_j;
            K(:,j) = K_i;
        end
        
        function [K] = LinearKernel(X)
            K = X * X';
        end
        
        function [K] = PolyKernel(X,d)
            K = (X * X').^d;
        end
        
        function [K] = RBFKernel(X,sigma)            
            n=size(X,1);
            K = Helpers.CreateDistanceMatrix(X);
            K = Helpers.distance2RBF(K,sigma);
        end 
        function [K] = Distance(X)
            K = Helpers.CreateDistanceMatrix(X,X);
        end
        function [D] = ComputeKernelDistance(K)
            DK = repmat(diag(K),1,size(K,2));
            D = DK + DK' - 2*K;
        end
    end
    
end

