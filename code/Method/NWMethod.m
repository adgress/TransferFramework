classdef NWMethod < HFMethod
    %NWMETHOD Nadaraya-Watson Estimator
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = NWMethod(configs)
            obj = obj@HFMethod(configs);
            obj.method = HFMethod.NW;
        end
        function [fu,savedData,sigma] = runNW(obj,distMat,makeRBF,savedData)
            assert(makeRBF);
            %distMat.W = Helpers.SimilarityToDistance(distMat.W);
            distMat.W = Helpers.distance2RBF(distMat.W,obj.get('sigma'));
            I = distMat.isLabeledTargetTrain();
            fu = zeros(length(I),distMat.numClasses);
            Wlabeled = distMat.W(I,:);
            a = sum(Wlabeled);
            %distMat.W(1:3,1:3)
            for labelIdx=1:distMat.numClasses
                currY = distMat.classes(labelIdx);
                currTrain = distMat.Y == currY & I;
                Wsub = distMat.W(currTrain,:);
                conf = sum(Wsub);
                fu(:,labelIdx) = conf';
            end
            Izero = sum(fu,2) == 0;
            fu(Izero,:) = rand([sum(Izero) 2]);
            fu = Helpers.NormalizeRows(fu);
            
            [~,savedData.predicted] = max(fu,[],2);
            savedData.cvAcc = [];
            sigma = obj.get('sigma');
        end
        function [s] = getPrefix(obj)
            s = 'NW';
        end
        function [nameParams] = getNameParams(obj)
            %nameParams = {'sigma','sigmaScale','k','alpha'};            
            nameParams = {'sigmaScale'};
            if obj.has('sigma') && length(obj.get('sigma')) == 1
                nameParams{end+1} = 'sigma';
            end
        end   
    end
    
end

