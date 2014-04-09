classdef HDHTransferMeasure < TransferMeasure
    %HDHTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods        
        function obj = HDHTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,metadata] = computeMeasure(obj,source,target,options)
            sourceY = ones(size(source.Y,1),1);
            targetY = 2*ones(size(target.Y,1),1);
            train = DataSet('','','',[source.X;target.X],[sourceY;targetY]);
            test = train;
            [results] = Helpers.trainAndTestSVM(train,test);
            val = sum(results.train.predicted==results.train.actual)/...
                numel(results.train.predicted);
            obj.displayMeasure(val);
            metadata = {};
        end
                        
        function [name] = getPrefix(obj)
            name = 'HDH';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
    end
    
end

