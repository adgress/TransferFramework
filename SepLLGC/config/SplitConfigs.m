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
        
        function [] = setSpam(obj)
            obj.delete('maxTrainNumPerLabel');
            obj.configsStruct.inputFilePrefix='../Data/pmtkdata-master/spamData/';
            obj.configsStruct.inputDataSets={'spamData.mat'};
            obj.configsStruct.dataSetAcronyms={'SPAM'};
            obj.configsStruct.outputFilePrefix='Data/spamData/';            
            obj.configsStruct.outputFile='spamData_split_data.mat';
            
            obj.set('XName',{'Xtrain','Xtest'});
            obj.set('YName',{'ytrain','ytest'});
        end
        
        function [] = setHousingBinary(obj)
            obj.delete('maxTrainNumPerLabel');
            obj.configsStruct.inputFilePrefix='/Data/housing/';
            obj.configsStruct.inputDataSets={'housingBinary.mat'};
            obj.configsStruct.dataSetAcronyms={'HB'};
            obj.configsStruct.outputFilePrefix='Data/housingBinary/';            
            obj.configsStruct.outputFile='housing_split_data.mat';
            
            obj.set('XName','X');
            obj.set('YName','yBinary');
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
        
        function [] = setUSPSSmall(obj)
            obj.setUSPS();
            obj.set('outputFilePrefix','Data/USPS-small/');
            %obj.set('maxTrainNumPerLabel',500);
            obj.set('numToUsePerLabel',300);
            obj.set('outputFile','splits.mat');
        end        
        
        function [] = setCOIL20(obj,classNoise)
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
            if classNoise > 0
                obj.set('outputFile',['splits-classNoise=' num2str(classNoise) '.mat']);
            end
            obj.set('classNoise',classNoise);
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

