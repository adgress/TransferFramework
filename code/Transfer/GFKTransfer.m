classdef GFKTransfer < Transfer
    %GFKTRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        parameters = {'d'}        
    end
    
    methods
        function obj = GFKTransfer()            
        end               
        
        function [transformedTargetTrain,transformedTargetTest,metadata,...
                tSource,tTarget] = ...
                performTransfer(obj,targetTrainData, targetTestData,...
                sourceDataSets,validateData,configs,savedData)            
            assert(numel(sourceDataSets) == 1);
            
            for str=obj.parameters
                eval([str{1} '= configs(''' str{1} ''');']);
            end
            
            sourceTrainData = sourceDataSets{1};
            transformedTargetTrain = targetTrainData;
            transformedTargetTest = targetTestData;                        
            
            [Psource,Ptarget] = Helpers.getSubspaces(sourceTrainData,...
                targetTrainData,targetTestData,configs);
            Xt = zscore([targetTrainData.X ; targetTestData.X]);
            %Xt = X(1:numTrain,:);
            %Xtt = X(numTrain+1:end,:);
            Xs = zscore(sourceTrainData.X);
            
            %Xs = sourceTrainData.X;
            Ys = sourceTrainData.Y;
            %Xt = [targetTrainData.X ; targetTestData.X];
            Yt = [targetTrainData.Y ; targetTestData.Y];
            
            G = GFK([Psource,null(Psource')],Ptarget(:,1:d));                        
            distST = repmat(diag(Xs*G*Xs'),1,length(Yt)) ...
                + repmat(diag(Xt*G*Xt')',length(Ys),1)...
                - 2*Xs*G*Xt';
            %{
            distTT2 = zeros(size(Xt,1));
            for i=1:size(Xt,1)
                for j=1:size(Xt,1)
                    xi = Xt(i,:);
                    xj = Xt(j,:);
                    Kii = xi*G*xi';
                    Kjj = xj*G*xj';
                    Kij = xi*G*xj';                    
                    d = Kii+Kjj-2*Kij;
                    distTT2(i,j) = d;
                end
            end
            %} 
            Dt = repmat(diag(Xt*G*Xt'),1,length(Yt));
            Ds = repmat(diag(Xs*G*Xs'),1,length(Ys));
            distTT = (Dt + Dt' - 2*Xt*G*Xt');
            distSS = (Ds + Ds' - 2*Xs*G*Xs');
            metadata = struct();
            Y = [targetTrainData.Y;-1*ones(numel(targetTestData.Y),1)...
                ; Ys ];
            type = [Constants.TARGET_TRAIN*ones(numel(targetTrainData.Y),1);...
                Constants.TARGET_TEST*ones(numel(targetTestData.Y),1);
                Constants.SOURCE*ones(numel(sourceTrainData.Y),1)];
            metadata.distanceMatrix = ...
                DistanceMatrix([distTT distST'; distST distSS],Y,type);
            tSource = sourceTrainData;
            tTarget = DataSet('','','',[targetTrainData.X;targetTestData.X],...
                [targetTrainData.Y;-1*ones(numel(targetTestData.Y),1)]);          
        end                   
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'d','usePLS'};
        end
    end
    
    methods(Static)        
        function [prefix] = getPrefix()
            prefix = 'GFK';
        end
        
        
    end
end

