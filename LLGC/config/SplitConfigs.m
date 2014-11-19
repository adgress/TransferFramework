classdef SplitConfigs < Configs
    %SPLITCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = SplitConfigs()
            obj = obj@Configs();
            obj.set('numSplits',10);
            obj.set('percentTrain',.8);
            obj.set('percentTest',.2);         
            obj.set('maxTrainNumPerLabel',Inf);
            obj.set('normalizeRows',0);
            obj.setUSPS();
        end
        
        function [] = setUSPSSmall(obj)
            obj.setUSPS();
            obj.set('outputFilePrefix','Data/USPS-small/');
            %obj.set('maxTrainNumPerLabel',500);
            obj.set('numToUsePerLabel',300);
            obj.set('outputFile','splits.mat');
        end
        
        function [] = setCOIL20(obj)
            obj.set('dataSetType','DataSet');
            obj.set('XName','fea');
            obj.set('YName','gnd');
            
            obj.set('maxTrainNumPerLabel',Inf);            
            obj.set('inputFilePrefix','Data/COIL20');
            obj.set('inputDataSets',{'COIL20.mat'});
            obj.set('dataSetAcronyms',{'COIL20'});
            obj.set('outputFilePrefix','Data/COIL20');
            obj.set('targetName','COIL20');
            obj.set('outputFile','splits.mat');
        end 
        
        function [] = setUSPS(obj)
            obj.set('dataSetType','DataSet');
            obj.set('XName','fea');
            obj.set('YName','gnd');
            
            obj.set('maxTrainNumPerLabel',Inf);            
            obj.set('inputFilePrefix','Data/USPS');
            obj.set('inputDataSets',{'USPS.mat'});
            obj.set('dataSetAcronyms',{'USPS'});
            obj.set('outputFilePrefix','Data/USPS');
            obj.set('targetName','USPS');
            obj.set('outputFile','splits.mat');
        end                                
    end
    
end

