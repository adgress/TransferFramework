classdef RODTransferMeasure < TransferMeasure
    %RODTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods        
        function obj = RODTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,perLabelMeasures,metadata] = computeMeasure(obj,source,target,options)
            [Psource,Ptarget] = Helpers.getSubspaces(source,...
                target, target, options);
            d = options('d');
            Psource = Psource(:,1:d);
            Ptarget = Ptarget(:,1:d);
            for i=1:size(Psource,2)
                v = Psource(:,i);
                u = Ptarget(:,i);
                Psource(:,i) = v/norm(v);                
                Ptarget(:,i) = u/norm(v);
            end
            
            P = Psource'*Ptarget;
            [U,S,V] = svd(P);
            thetas = sort(acos(diag(S)),'descend');
            vals = zeros(size(Psource,2),1);
            for i=1:size(Psource,2)
                v = Psource(:,i);
                u = Ptarget(:,i);
                theta = thetas(i);
                projectedS = source.X*v;
                projectedT = target.X*u;
                d1 = RODTransferMeasure.getSymKLDiv(projectedT,projectedT);
                d2 = RODTransferMeasure.getSymKLDiv(projectedS,projectedS);
                div = RODTransferMeasure.getSymKLDiv(projectedS,projectedT);
                vals(i) = inv(i)*theta*div;
            end
            val = sum(vals);
            metadata = {};
            perLabelMeasures = [];
        end
                        
        function [name] = getPrefix(obj)
            name = 'ROD';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'d','usePLS'};
        end
    end
    
    methods(Static)
        function [div] = getSymKLDiv(s,t)
            div = RODTransferMeasure.getKLDiv(s,t)+...
                RODTransferMeasure.getKLDiv(t,s);
        end
        function [div] = getKLDiv(s,t)
            m0 = mean(s);
            m1 = mean(t);
            v0 = var(s);
            v1 = var(t);
            div = .5*(inv(v1)*v0 + inv(v1)*(m1-m0)^2 - 1 - log(v0/v1));
            assert(div >= -1e9);
        end
    end
end

