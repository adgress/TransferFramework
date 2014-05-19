classdef CCA < DRMethod
    %DRCCA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = CCA(configs)
            obj = obj@DRMethod(configs);
        end
        function [modData,metadata] = performDR(data,configs)
            train = data.train;
            test = data.test;
            validate = data.validate;
            
            setsToUse = configs('setsToUse');
            X = data.X(setsToUse);
            assert(length(setsToUse) == 2);
            Wij = obj.getSubW(setsToUse(1),setsToUse(2));
            
            X1 = X{setsToUse(1)};
            X2 = X{setsToUse(2)};
            
            metadata = struct();
        end

        function [prefix] = getPrefix(obj)
            prefix = 'CCA';
        end
        
        function [d] = getDirectory(obj)
            d = 'CCA';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        
    end
    
end

