classdef Kernel < handle
    %KERNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
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
        
%From http://www.kernel-methods.net/matlab/kernels/rbf.m        
        function [K] = RBFKernel(X,sigma)            
            n=size(X,1);
            %{
            XX = X*X';
            K=XX./(sigma^2);
            d=diag(K);
            K=K-ones(n,1)*d'/2;
            K=K-d*ones(1,n)/2;
            K=exp(K);            
            min(eig(K))            
            %}            
            %{
            min(eig(K3))
            for i=1:n
                for j=1:n
                    xi = X(i,:);
                    xj = X(j,:);
                    K2(i,j) = exp(norm(xi-xj)^2/(-2*sigma^2));
                end
            end            
            min(eig(K2))
            norm(K2-K3,Inf)
            %}
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

