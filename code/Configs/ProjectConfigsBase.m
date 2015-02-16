classdef ProjectConfigsBase < handle
    %PROJECTCONFIGSBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numTarget
        numSource
        tommasiLabels
    end
    
    methods
        function [obj] = ProjectConfigsBase()
            obj.numTarget = 2;
            obj.numSource = 2;
            obj.tommasiLabels = [10 15 25 23 26 30 41 56 57];
        end
        function [labelProduct] = MakeLabelProduct(obj)            
            numTargetLabels = obj.numTarget;
            numSourceLabels = obj.numSource;
            targetlabels = obj.tommasiLabels(1:numTargetLabels);
            sourceLabels = obj.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);
            targetDomains = Helpers.MakeCrossProductOrdered(targetlabels,targetlabels);
            sourceDomains = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);
            labelProduct = Helpers.MakeCrossProduct(targetDomains,sourceDomains);
        end
        
        function [targetDomains,sourceDomains] = MakeDomains(obj)            
            numTargetLabels = obj.numTarget;
            numSourceLabels = obj.numSource;
            
            targetlabels = obj.tommasiLabels(1:numTargetLabels);
            targetDomains = Helpers.MakeCrossProductOrdered(targetlabels,targetlabels);
            
            sourceLabels = obj.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);            
            sourceDomains = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);           
        end
        
        function [targetLabels,sourceLabels] = GetTargetSourceLabels(obj)
            numTargetLabels = obj.numTarget;
            numSourceLabels = obj.numSource;
            targetLabels = obj.tommasiLabels(1:numTargetLabels);
            sourceLabels = obj.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);
        end        
    end
    
end

