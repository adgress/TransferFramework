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
        
        function [results, metadata] = ...
                runExperiment(obj,train,test,validate,experiment)
            methodClass = str2func(experiment.methodClass);
            methodObject = methodClass();
            percTrain = experiment.trainSize;
            numTrain = ceil(percTrain*size(train.X,1));
            [trainX,trainY] = train.stratifiedSample(numTrain);
            sampledTrain = DataSet('','','',trainX,trainY);
            [results,metadata] = ...
                methodObject.trainAndTest(sampledTrain,test,validate,experiment);
        end
    end
    methods(Abstract)        
    end
    
end

