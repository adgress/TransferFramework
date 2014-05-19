classdef DRMethod < Saveable
    %DRMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configs
    end
    
    methods      
        function [obj] = DRMethod(configs)
            obj.configs = configs;
        end
        function [modData,metadata] = performDR(data,configs)
            modData.train = SimilarityDataSet(data.train.X,data.train.W);
            modData.test = SimilarityDataSet(data.test.X,data.test.W);
            modData.validate = SimilarityDataSet(data.validate.X,...
                data.validate.W);
            metadata = struct();
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

