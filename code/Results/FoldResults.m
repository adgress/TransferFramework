classdef FoldResults < handle
    %FOLDRESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        trainType
        testType
        trainFU
        testFU
        testPredicted
        testActual
        trainPredicted
        trainActual
        learnerMetadata
        trainingDataMetadata
        
        sources
        sampledTrain
        test
    end
    
    properties(Dependent)
        metadata
    end
    
    methods
        function obj = FoldResults()
            obj.trainType = [];
            obj.testType = [];
            obj.trainFU = [];
            obj.testPredicted = [];
            obj.testActual = [];
            obj.trainPredicted = [];
            obj.trainActual = [];
            obj.learnerMetadata = struct();
            obj.trainingDataMetadata = struct();
            
            obj.sources = [];
            obj.sampledTrain = [];
            obj.test = [];
        end        
       
        
        function [] = set.metadata(obj, m)
            error('Deprecated - use learnerMetadata');
        end        
        function [v] = get.metadata(obj)
            v = [];
            display('Deprecated - use learnerMetadata');            
        end
        
    end
    
end

