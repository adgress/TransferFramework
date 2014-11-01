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
        end
        
        function [] = setCVSmall(obj)
            obj.setCV();
            obj.set('outputFilePrefix','Transfer/Data/CV-small/');
            obj.set('maxTrainNumPerLabel',15);
        end
        
        function [] = setCV(obj)
            obj.set('dataSetType','DataSet');
            obj.set('XName','fts');
            obj.set('YName','labels');
            
            obj.set('maxTrainNumPerLabel',Inf);            
            obj.set('inputFilePrefix','Data/GFK/data/');
            obj.set('inputDataSets',{'amazon_SURF_L10.mat','Caltech10_SURF_L10.mat','dslr_SURF_L10.mat','webcam_SURF_L10.mat'});
            obj.set('dataSetAcronyms',{'A','C','D','W'});
            obj.set('outputFilePrefix','Transfer/Data/CV/');
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
            obj.configsStruct.outputFilePrefix='Transfer/Data/tommasi_data/';            
            obj.configsStruct.backgroundClass = 257;
            obj.configsStruct.outputFile='tommasi_split_data.mat';
        end
        
        function [] = set20NG(obj)            
            obj.set('XName','X');
            obj.set('YName','Y');
            obj.delete('maxTrainNumPerLabel');
            %obj.set('normalizeRows','1');
            %maxTrain=1000
            
            obj.configsStruct.inputFilePrefix='Data/20news-bydate/Domains/';
            obj.configsStruct.inputDataSets={'CR1.mat','CR2.mat','CR3.mat','CR4.mat'};
            obj.configsStruct.dataSetAcronyms={'CR1','CR2','CR3','CR4'};
            obj.configsStruct.outputFilePrefix='Data/20news-bydate/splitData/';
        end
    end
    
end

