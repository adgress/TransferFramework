classdef ExperimentManager < handle
    %EXPERIMENTMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        %How do I do an empty constructor?
        %{
        function [obj] = ExperimentManager()            
        end
        %}
        
        function [results] = ...
                runExperiment(obj,train,test,validate,experiment)
            learner = experiment.learner;
            percTrain = experiment.trainSize;
            numTrain = ceil(percTrain*size(train.X,1));
            [trainX,trainY] = train.stratifiedSample(numTrain);
            sampledTrain = DataSet('','','',trainX,trainY);
            [results] = ...
                learner.trainAndTest(sampledTrain,test,validate,experiment);
        end
    end
    methods(Abstract)        
    end
    
end

