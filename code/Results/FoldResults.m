classdef FoldResults <  matlab.mixin.Copyable
    %FOLDRESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
        learnerMetadata
        trainingDataMetadata
        
        dataType
        dataFU
        yPred
        yActual
        
        sources
        sampledTrain
        test
        
        isNoisy
        instanceWeights
        
        %dataSetWeights
        ID2Labels
        learnerStats
    end
    properties(Dependent)
        trainType
        testType
        trainFU
        testFU
        testPredicted
        testActual
        trainPredicted
        trainActual        
    end
    
    methods
        function obj = FoldResults()
            obj.dataType=[];
            obj.dataFU=[];
            obj.yPred=[];
            obj.yActual=[];
            obj.learnerMetadata = struct();
            obj.trainingDataMetadata = struct();
            
            obj.sources = [];
            obj.sampledTrain = [];
            obj.test = [];
            obj.learnerStats = struct();
        end    
        function [v] = get.trainType(obj)
            %{
            if isequal(obj.dataFU, [])
                v = [];
                return;
            end
            %}
            v = obj.dataType(obj.isTrain());
            obj.assertSize();
        end
        function [v] = get.testType(obj)
            %{
            if isequal(obj.dataFU, [])
                v = [];
                return;
            end
            %}
            v = obj.dataType(obj.isTest());
            obj.assertSize();
        end                
        function [v] = get.trainFU(obj)
            if isequal(obj.dataFU, [])
                v = [];
                return;
            end
            v = obj.dataFU(obj.isTrain(),:);
            obj.assertSize();
        end        
        function [v] = get.testFU(obj)
            if isequal(obj.dataFU, [])
                v = [];
                return;
            end
            v = obj.dataFU(obj.isTest(),:);
            obj.assertSize();
        end        
        function [v] = get.trainPredicted(obj)
            %{
            if isequal(obj.dataFU, [])
                v = [];
                return;
            end
            %}
            v = [];
            if isempty(obj.yPred)
                return;
            end
            v = obj.yPred(obj.isTrain(),:);
            obj.assertSize();
        end        
        function [v] = get.testPredicted(obj)
            %{
            if isequal(obj.dataFU, [])
                v = [];
                return;
            end
            %}
            v = [];
            if isempty(obj.yPred)
                return;
            end
            v = obj.yPred(obj.isTest(),:);
            obj.assertSize();            
        end        
        function [v] = get.trainActual(obj)
            %{
            if isequal(obj.dataFU, [])
                v = [];
                return;
            end
            %}
            v = obj.yActual(obj.isTrain(),:);
            obj.assertSize();
        end      
        function [v] = get.testActual(obj)
            %{
            if isequal(obj.dataFU, [])
                v = [];
                return;
            end
            %}
            v = obj.yActual(obj.isTest(),:);
            obj.assertSize();
        end 
        
        function [inds] = isTrain(obj)
            inds = obj.dataType == Constants.TARGET_TRAIN | ...
                obj.dataType == Constants.SOURCE;
        end
        function [inds] = isTest(obj)
            inds = ~obj.isTrain();
        end 
        
        function assertSize(obj)
            fields = {'yPred', 'yActual', 'dataFU'};
            numInstances = numel(obj.dataType);
            for fieldItr=1:length(fields)
                field = fields{fieldItr};
                fieldValue = obj.(field);
                fieldSize = size(fieldValue,1);
                assert(fieldSize == 0 || fieldSize == numInstances);
            end
            assert(all(obj.dataType == Constants.TARGET_TRAIN | ...
                obj.dataType == Constants.TARGET_TEST | ...
                obj.dataType == Constants.SOURCE));
        end
    end
    
    methods(Access = protected)
               
    end
    
end

