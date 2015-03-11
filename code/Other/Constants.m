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
        
        NO_TYPE = 0;
        TARGET_TRAIN = 1;
        TARGET_TEST = 2;
        SOURCE = 3;
        
        TRAIN = 1;
        VALIDATE = 2;
        TEST = 3;
    end
    
    methods
    end
    
end

