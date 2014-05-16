function [ newMat ] = applyThresholdOnSimMat( inMat, threshold )

    newMat=inMat;
    for i=1:size(inMat,1)
        for j=1:size(inMat,2)
            %newMat(i,j)=1-1/exp(inMat(i,j));                    
            if (inMat(i,j)<threshold)
                newMat(i,j)=0;
            end
        end
    end
    
end

