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
        end
        
        function [] = setSyntheticTransfer(obj,directory,targetSuffix,sourceSuffix)
            obj.set('XName','X');
            obj.set('YName','Y');
            obj.set('regProb',true);
            obj.delete('maxTrainNumPerLabel');
            
            obj.configsStruct.inputFilePrefix=directory;
            targetFile = ['target,' targetSuffix '.mat'];
            sourceFile = ['source,' sourceSuffix '.mat'];
            obj.configsStruct.inputDataSets=...
                {targetFile,sourceFile};
            obj.configsStruct.dataSetAcronyms=...
                {'T','S'};
            obj.configsStruct.outputFilePrefix= [directory '/splitData/'];
            obj.configsStruct.outputFile='';
            obj.set('fieldsToSave',{'beta','beta0','sigma','degree','trueY'});
        end
        
        function [] = setITS(obj,dataSet,useReg,useStudQGraph)
            if ~exist('dataSet','var')
                dataSet = 'DS1';
            end
            if ~exist('useReg','var')
                useReg = false;
            end
            obj.delete('maxTrainNumPerLabel');
            obj.configsStruct.inputFilePrefix='Data/ITS/';
            obj.configsStruct.inputDataSets={[dataSet '.mat']};

            obj.configsStruct.dataSetAcronyms={dataSet};
            obj.configsStruct.outputFilePrefix='Data/ITS/';
            obj.configsStruct.outputFile=[dataSet '_split_data.mat'];
            obj.delete('XName');
            obj.set('WName','W');
            obj.set('YName','Y');
            obj.set('includeDataStruct',true);
            %obj.set('WIDs','');
            %obj.set('WNames','');
            if useReg
                obj.set('regProb',true);
                obj.set('WName','studentW');
                obj.set('YName','studentSkills');
                obj.configsStruct.outputFile=[dataSet '_split_data.mat'];
                if useStudQGraph
                    obj.set('WName','studentQuestionW');
                    obj.configsStruct.outputFile=[dataSet '_SQgraph_split_data.mat'];
                end
            end
        end
        function [] = setYeastUCIBinary(obj)
            obj.delete('maxTrainNumPerLabel');
            
            obj.configsStruct.inputFilePrefix='Data/pmtkdata-master/yeastUci/';
            obj.configsStruct.inputDataSets={'yestUci_binary.mat'};
            obj.configsStruct.dataSetAcronyms={'YeastBinary'};
            obj.configsStruct.outputFilePrefix='Data/yeastBinary/';            
            obj.configsStruct.outputFile='yeastBinary_split_data.mat';
            obj.set('numToUsePerLabel',150);
            obj.set('XName','X');
            obj.set('YName','y');            
        end
        
        function [] = setSpam(obj)
            obj.delete('maxTrainNumPerLabel');
            obj.configsStruct.inputFilePrefix='Data/pmtkdata-master/spamData/';
            obj.configsStruct.inputDataSets={'spamData.mat'};
            obj.configsStruct.dataSetAcronyms={'SPAM'};
            obj.configsStruct.outputFilePrefix='Data/spamData/';            
            obj.configsStruct.outputFile='spamData_split_data.mat';
            
            obj.set('XName',{'Xtrain','Xtest'});
            obj.set('YName',{'ytrain','ytest'});
        end
        
        function [] = setHousingBinary(obj)
            obj.delete('maxTrainNumPerLabel');
            obj.configsStruct.inputFilePrefix='Data/housingBinary/';
            obj.configsStruct.inputDataSets={'housingBinary.mat'};
            obj.configsStruct.dataSetAcronyms={'HB'};
            obj.configsStruct.outputFilePrefix='Data/housingBinary/';            
            obj.configsStruct.outputFile='housing_split_data.mat';
            
            obj.set('XName','X');
            obj.set('YName','yBinary');
        end
        
        function [] = setCVSmall(obj,sourceNoise)
            if ~exist('sourceNoise','var')
                sourceNoise = 0;
            end
            obj.setCV();            
            obj.set('maxTrainNumPerLabel',20);
            outputFilePrefix = 'Data/CV-small';
            if sourceNoise > 0
                obj.set('sourceNoise',sourceNoise);
                outputFilePrefix = [outputFilePrefix '-' num2str(sourceNoise)];                   
            end
            obj.set('outputFilePrefix',[outputFilePrefix '/']);
        end
        
        function [] = setCV(obj)
            obj.set('dataSetType','DataSet');
            obj.set('XName','fts');
            obj.set('YName','labels');
            
            obj.set('maxTrainNumPerLabel',Inf);            
            obj.set('inputFilePrefix','Data/GFK/data/');
            obj.set('inputDataSets',{'amazon_SURF_L10.mat','Caltech10_SURF_L10.mat','dslr_SURF_L10.mat','webcam_SURF_L10.mat'});
            obj.set('dataSetAcronyms',{'A','C','D','W'});
            obj.set('outputFilePrefix','Data/CV/');
        end
        
        function [] = setClassNoise(obj,classNoise)
            obj.set('classNoise',classNoise);
            a = obj.get('outputFile');
            i = strfind(a,'.mat');
            if ~isempty(i)
                a = a(1:i-1);
            end
            i = strfind(a,'-classNoise=');
            if ~isempty(i)
                a = a(1:i-1);
            end
            a = [a '-classNoise=' num2str(classNoise) '.mat'];
            obj.set('outputFile',a);
        end
        
        function [] = setTommasi(obj,classNoise)
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
            if classNoise > 0
                obj.set('outputFile',['tommasi_split_data-classNoise=' num2str(classNoise) '.mat']);
            end
            obj.set('classNoise',classNoise);
        end
        
        function [] = set20NG(obj)            
            obj.set('XName','X');
            obj.set('YName','Y');
            obj.set('maxTrainNumPerLabel',300);
            %obj.delete('maxTrainNumPerLabel');
            %obj.set('normalizeRows','1');
            %maxTrain=1000
            
            obj.configsStruct.inputFilePrefix='Data/20news-bydate/Domains/';
            obj.configsStruct.inputDataSets=...
                {'CR1.mat','CR2.mat','CR3.mat','CR4.mat',...
                'ST1.mat','ST2.mat','ST3.mat','ST4.mat'};
            obj.configsStruct.dataSetAcronyms=...
                {'CR1','CR2','CR3','CR4','ST1','ST2','ST3','ST4'};
            obj.configsStruct.outputFilePrefix='Data/20news-bydate/splitData/';
            obj.configsStruct.outputFile='';
            obj.set('minInstancesPerFeature',100);
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

