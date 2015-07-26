classdef Constants < handle
    %CONSTANTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        RELATIVE_PERFORMANCE = 1
        CORRELATION = 2
        DIFF_PERFORMANCE = 3
        
        CV_DATA = 1
        NG_DATA = 2
        TOMMASI_DATA = 3
        COIL20_DATA = 4
        USPS_DATA = 5
        HOUSING_DATA = 6
        YEAST_BINARY_DATA = 7
        ITS_DATA = 8
        
        %Used for plotting multiple data sets
        ALL_DATA = 100
        
        NO_TYPE = 0;
        TARGET_TRAIN = 1;
        TARGET_TEST = 2;
        SOURCE = 3;
        
        TRAIN = 1;
        VALIDATE = 2;
        TEST = 3;
        
        STUDENT = 1
        STEP = 2
        STEP_CORRECT = 3
        STEP_INCORRECT = 4
    end
    
    methods
    end
    
end

