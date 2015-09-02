classdef ProjectConfigsBase < handle
    %PROJECTCONFIGSBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numTarget
        numSource
        tommasiLabels
        
        rerunExperiments
        multithread
        computeLossFunction
        processMeasureResults
        numLabeledPerClass
        
        dataSet
        numRandomFeatures
        
        makeSubDomains
        labelNoise
        
        smallResultsFiles
        labelsToKeep
        remapLabels
        
        useSavedSmallResults
        
        preprocessDataFunc
        
        useSVM
        useNB
        fixReg
        logRegNumFeatures
        useL1LogReg
        resampleTarget
    end
    
    methods
        function [obj] = ProjectConfigsBase()            
            obj.remapLabels = false;
            obj.useSavedSmallResults = false;
            obj.numLabeledPerClass = -1;
            obj.numTarget = 2;
            obj.numSource = 2;
            obj.tommasiLabels = [10 15 25 23 26 30 41 56 57];
            obj.rerunExperiments=0;
            
            obj.multithread=0;
            obj.rerunExperiments=0;
            
            obj.computeLossFunction=1;
            obj.processMeasureResults=0;
            obj.dataSet = -1;
            obj.numRandomFeatures = 0;
            obj.makeSubDomains = false;
            obj.labelNoise = 0;
            obj.smallResultsFiles = true;
            obj.labelsToKeep = [];
            
            obj.useSVM = 0;
            obj.useNB = 0;
            obj.fixReg = 0;
            obj.logRegNumFeatures = inf;
            obj.useL1LogReg = 0;
            obj.resampleTarget = 0;
        end
        function [labelProduct] = MakeLabelProduct(obj)         
            error('Shouldn''t this be in MainConfigs?');
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
            error('Shouldn''t this be in MainConfigs?');
            numTargetLabels = obj.numTarget;
            numSourceLabels = obj.numSource;
            targetLabels = obj.tommasiLabels(1:numTargetLabels);
            sourceLabels = obj.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);
        end        
    end
    
end

