classdef ActiveLearningL2Measure < ActiveLearningMeasure
    %ACTIVELEARNINGL2MEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        l2Measure
    end
    
    methods
        function obj = ActiveLearningL2Measure(configs)
            if ~exist('configs','var')
                configs = [];
            end
            obj = obj@ActiveLearningMeasure(configs);
            obj.l2Measure = L2Measure();
        end
        function [valTrain,valTest] = computeTrainTestResults(obj,r)
            [valTrain,valTest] = obj.l2Measure.computeTrainTestResults(r);
        end
    end
    
end

