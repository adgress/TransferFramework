classdef SplitConfigs < Configs
    %SPLITCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = SplitConfigs()
            obj = obj@Configs();
            obj.set('numSplits',30);
            obj.set('percentTrain',.8);
            obj.set('percentTest',.2);         
            obj.set('maxTrainNumPerLabel',Inf);
            obj.set('normalizeRows',0);
            obj.setUSPS();
        end
        
        
        function [] = setTommasi(obj)
            obj.set('XName','X');
            obj.set('YName','Y');
            %obj.set('normalizeRows','1');
            %maxTrain=1000
            obj.delete('maxTrainNumPerLabel');
            obj.configsStruct.inputFilePrefix='Data/tommasi_data/';
            obj.configsStruct.inputDataSets={'tommasi_data.mat'};
            obj.configsStruct.dataSetAcronyms={'TD'};
            obj.configsStruct.outputFilePrefix='Data/tommasi_data/';            
            obj.configsStruct.backgroundClass = 257;
            obj.configsStruct.outputFile='tommasi_split_data.mat';
        end                                               
    end
    
end

