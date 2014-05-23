classdef DRMethod < Saveable
    %DRMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods      
        function [obj] = DRMethod(configs)
            obj = obj@Saveable(configs);
        end
        function [modData,metadata] = performDR(obj,data)
            modData = struct();
            modData.train = SimilarityDataSet(data.train.X,data.train.W);
            modData.test = SimilarityDataSet(data.test.X,data.test.W);
            modData.validate = SimilarityDataSet(data.validate.X,...
                data.validate.W);
            metadata = struct();
        end
        
        function [modData] = applyProjection(obj,data,setsToUse,projections,means)
            if isempty(data)
                modData = [];
                return;
            end
            projectedData = cell(length(setsToUse),1);
            for i=1:length(setsToUse)
                X = data.X{setsToUse(i)};
                X = Helpers.CenterData(X,means{i});
                X = X*projections{i};
                projectedData{i} = X;
            end
            modData = SimilarityDataSet(projectedData,data.getSubW(setsToUse));
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'No-DR';
        end        
        function [d] = getDirectory(obj)
            d = '';
        end        
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end        
    end
    
end

