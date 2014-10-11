classdef GraphMeasureResults < FoldResults
    %GRAPHMEASURERESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        score
        percCorrect
        measureMetadata
        perLabelMeasures
        
        labeledTargetScores
    end
    
    methods
         function obj = GraphMeasureResults()
            obj = obj@FoldResults();
        end      
    end
    
end

