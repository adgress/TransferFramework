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

            distMat.W = Helpers.distance2RBF(distMat.W,obj.get('sigma'));
            I = distMat.isLabeledTargetTrain();            

            if distMat.isRegressionData
                Wlabeled = distMat.W(:,I);
                D = diag(sum(Wlabeled,2));
                fu = zeros(size(distMat.Y));
                assert(size(fu,2) == 1);
                warning off;
                fu = inv(D)*Wlabeled*distMat.Y(I);
                warning on;
                
            else
                Wlabeled = distMat.W(I,:);
                fu = zeros(length(I),distMat.numClasses);
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

                [~,fu] = max(fu,[],2);
            end
            isInvalid = isnan(fu) | isinf(fu);
            if any(isInvalid(:))
                %display('LLGC:llgc_ls : inf or nan - randing out');
                r = rand(size(fu));
                fu(isInvalid) = r(isInvalid);
            end
            savedData.predicted = fu;
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

