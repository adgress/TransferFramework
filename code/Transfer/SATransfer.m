classdef SATransfer < GFKTransfer
    %SATRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
    end
    
    methods
        function obj = SATransfer()            
        end
        

        function [transformedTargetTrain,transformedTargetTest,metadata,...
                tSource, tTarget] = ...
                performTransfer(obj,targetTrainData, targetTestData,...
                sourceDataSets,validateData,configs,savedData)            
            assert(numel(sourceDataSets) == 1);
            
            for str=obj.parameters
                eval([str{1} '= configs(''' str{1} ''');']);
            end            

            sourceTrainData = sourceDataSets{1};
            
            numTrain = size(targetTrainData.X,1);
            X = zscore([targetTrainData.X ; targetTestData.X]);
            Xt = X(1:numTrain,:);
            Xtt = X(numTrain+1:end,:);
            Xs = zscore(sourceTrainData.X);
            %{
            [Xt,XtMean] = Helpers.CenterData(Xt);
            Xtt = Helpers.CenterData(Xtt,XtMean);
            Xs = Helpers.CenterData(Xs);
            %}
            %transformedTargetTrain = targetTrainData;
            %transformedTargetTest = targetTestData;
            display('TODO: Whiten data??? Is this causing bad performance?');
            
            centeredTargetTrain = DataSet('','','',Xt,targetTrainData.Y);
            centeredTargetTest = DataSet('','','',Xtt,targetTestData.Y);
            centeredSource = DataSet('','','',Xs,sourceTrainData.Y);
            [Psource,Ptarget] = Helpers.getSubspaces(centeredSource,...
                centeredTargetTrain,centeredTargetTest,configs);
            %{
            [Psource,Ptarget] = obj.getSubspaces(sourceTrainData,...
                targetTrainData,targetTestData,configs);
            %}
            Psource = Psource(:,1:d);
            Ptarget = Ptarget(:,1:d);
            M = Psource*Ptarget';
            
            tSource = DataSet('','','',Xs*M*Ptarget,sourceTrainData.Y);
            
            tTarget = DataSet('','','',X*Ptarget,[targetTrainData.Y ; ...
                -1*ones(numel(targetTestData.Y),1)]);
            targetX = [Xt*Ptarget; tSource.X];
            targetY = [targetTrainData.Y;sourceTrainData.Y];
            transformedTargetTrain = DataSet('','','',targetX,targetY);
            transformedTargetTest = DataSet('','','',...
                Xtt*Ptarget,targetTestData.Y);
            metadata = struct();
            metadata.Psource = Psource;
            metadata.Ptarget = Ptarget;
            metadata.configs = configs;
        end        
        function [nameParams] = getNameParams(obj)
            nameParams = {'d','usePLS'};
        end
    end
    methods(Static)
        function [prefix] = getPrefix()
            prefix = 'SA';
        end
    end
    
end

