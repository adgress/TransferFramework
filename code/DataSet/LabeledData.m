classdef LabeledData < matlab.mixin.Copyable
    %LABELEDDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Y
        type
    end
    
    properties(Dependent)
        numClasses
        classes
    end
    
    methods
        function [obj] = LabeledData()
            obj.Y = [];
            obj.type = [];
        end
        
        function [] = clearLabels(obj, shouldClearLabels)
            obj.Y(shouldClearLabels) = -1;
        end
        
        function [] = swapSourceAndTarget(obj)
            targetInds = obj.isTarget();
            obj.type(targetInds) = Constants.SOURCE;
            obj.type(~targetInds) = Constants.TARGET_TRAIN;
        end
        function [I] = isTarget(obj)
            I = obj.type == Constants.TARGET_TRAIN | ...
                obj.type == Constants.TARGET_TEST;
        end
        
        function [I] = isLabeledTarget(obj)
            I = obj.isTarget() & obj.isLabeled();
        end
        
        function [I] = isUnlabeledTarget(obj)
            I = obj.isTarget() & ~obj.isLabeled();
        end
        
        function [I] = isSource(obj)
            I = obj.type == Constants.SOURCE;
        end
        
        function [I] = isLabeledSource(obj)
            I = obj.isSource() & obj.isLabeled();
        end
        
        function [I] = isLabeled(obj)
            I = obj.Y > 0;
        end
        
        function [n] = get.numClasses(obj)
            n = length(obj.classes());
        end
        
        function [v] = get.classes(obj)
            v = unique(obj.Y(obj.isLabeled));
        end
        
        function [n] = size(obj)
            n = length(obj.Y);
        end
        
        function [n] = numSource(obj)
            n = sum(obj.type == Constants.SOURCE);
        end
        function [n] = numLabeledSource(obj)
            n = sum(obj.Y > 0 & ...
                obj.type == Constants.SOURCE);
        end
        
        function [Yu] = getBlankLabelVector(obj)
            Yu = obj.Y;
            Yu(:) = -1;
        end
        function [b] = hasTypes(obj)
            b = length(obj.Y) == length(obj.type) && ...
                isempty(find(obj.type == Constants.NO_TYPE));
        end
        function [b] = isSourceDataSet(obj)
            b = sum(obj.type == Constants.SOURCE) == length(obj.Y);            
        end
        function [b] = isTargetDataSet(obj)
            b = sum(obj.type == Constants.TARGET_TRAIN | ...
                obj.type == Constants.TARGET_TEST) == length(obj.Y);            
        end
        
        function [] = setTargetTrain(obj)
            obj.type = DataSet.TargetTrainType(obj.size());
        end
        function [] = setTargetTest(obj)
            obj.type = DataSet.TargetTestType(obj.size());
        end
        function [] = setSource(obj)
            obj.type = DataSet.SourceType(obj.size());
        end
        function [] = removeTestLabels(obj)
            obj.Y(obj.type == Constants.TARGET_TEST) = -1;
        end 
    end

    methods(Static)        
        function [v] = TargetTrainType(n)
            v = Constants.TARGET_TRAIN*ones(n,1);
        end
        function [v] = TargetTestType(n)
            v = Constants.TARGET_TEST*ones(n,1);
        end
        function [v] = SourceType(n)
            v = Constants.SOURCE*ones(n,1);
        end
        function [v] = NoType(n)
            v = Constants.NO_TYPE*ones(n,1); 
        end
    end
end

