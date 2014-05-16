function [ sparseMat ] = convertSparseColumnsToSparseMat( threeColumnMatrix )

    sizeOfMat=max(threeColumnMatrix(:,1));

    sparseMat1=threeColumnMatrix;
    sparseMat2=threeColumnMatrix;
    sparseMat2(:,1)=sparseMat1(:,2);
    sparseMat2(:,2)=sparseMat1(:,1);
    for i=1:size(threeColumnMatrix,1);        
        if (sparseMat2(i,1)==sparseMat2(i,2))
            sparseMat2(i,3)=0;
        end
    end

    temp=[sparseMat1; sparseMat2];
    
    sparseMat = spconvert(temp);
    
end

