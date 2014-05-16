classdef DataContainer
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        views
        intraViewKernels
        interViewKernels
        kernelsToUse
    end
    
    methods
        function obj = DataContainer()
            obj.views = {};
            numViews = numel(obj.views);
            obj.intraViewKernels = cell(numViews);
            obj.interViewKernels = cell(numViews,numViews);
            obj.kernelsToUse = zeros(numViews);
            
        end
    end
    
end

