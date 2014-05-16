function [a,b,c,tagSamples] = embedKCCA(tagSimMat,imageSimMat,imageTagsSimMat,options)
    addpath('CCA (Sun)\utilities');
    %PROBLEM: How do I project individual tags? 
    KImageTags = zeros(size(imageSimMat));
    Km_dupe = [];
    Kt_dupe = [];
    for i=1:size(imageTagsSimMat,1)
        image_i = imageSimMat(i,:);
        for j=1:size(imageTagsSimMat,2)
            if imageTagsSimMat(i,j) == 0
                continue;
            end
            tag_j = tagSimMat(j,:);
            Km_dupe(:,end+1) = image_i;
            Kt_dupe(:,end+1) = tag_j;
        end
    end
    %{
    for i=1:size(imageSimMat,1)
        vi = imageTagsSimMat(i,:);
        for j=i:size(imageSimMat,1)            
            vj = imageTagsSimMat(j,:);
            kij = sum(vi & vj)/sum(vi | vj);
            if isnan(kij)
                kij = 0;
            end
            if i==j
                kij = 1;
            end
            KImageTags(i,j) = kij;
            KImageTags(j,i) = kij;          
        end
    end    
    [a, c, r] = kcanonca_reg_ver1(imageSimMat,KImageTags,1,0);
    tagSamples = getSingleTagSamples(imageTagsSimMat,tagSimMat);    
    [a, c, r] = kcanonca_reg_ver1(Km_dupe,Kt_dupe,1,0);
    tagSamples = tagSimMat;
    %}
    b = [];
    tagSamples = [];    
    
    %[a,c,R] = canoncorr(Km_dupe,Kt_dupe);    
    
    
    Km_dupe = (Km_dupe-repmat(mean(Km_dupe,2),1,size(Km_dupe,2)));
    Kt_dupe = (Kt_dupe-repmat(mean(Kt_dupe,2),1,size(Kt_dupe,2)));
    %[a,c] = cca_borga(Km_dupe,Kt_dupe);
    
    %{
    CCAOptions = struct();
    CCAOptions.RegX = options.reg;
    CCAOptions.RegY = options.reg;
    [a,c,d] = CCA(Km_dupe,Kt_dupe,CCAOptions);    
    %}
  
    X = Km_dupe;
    Y = Kt_dupe;
    Cyy = Y*Y';
    Cyy = Cyy + options.reg*eye(size(Cyy));
    Cyy_inv = inv(Cyy);
    Cxx = X*X';
    Cxx = Cxx + options.reg*eye(size(Cxx));
    K = X*Y'*Cyy_inv*Y*X';
    %K = K + options.reg*eye(size(K));
    [vecs,vals] = eig(K,Cxx);
    [sortedVals,I] = sort(diag(vals),'descend');        
    a = vecs(:,I);
    discardFirstEigenvector = 0;
    if discardFirstEigenvector
        a = a(:,2:end);
    end

    
    numVecs = size(a,2);
    for i=1:size(a,2)
        ai = a(:,i);
        %a(:,i) = ai/norm(ai);
        a(:,i) = ai/sqrt(ai'*Cxx*ai);
    end
    c = Cyy_inv*Y*X'*a;
    for i=1:size(c,2)
        ci = c(:,i);
        c(:,i) = ci/sqrt(ci'*Cyy*ci);
    end
end

function [samples] = getSingleTagSamples(imageTagsSimMat,tagSimMat)
    samples = zeros(size(tagSimMat,1),size(imageTagsSimMat,1));
    for i=1:size(samples,1)
        for j=1:size(imageTagsSimMat,1)
            vj = imageTagsSimMat(j,:);
            samples(i,j) = vj(i)/max(1,sum(vj));
        end  
        s = samples(i,:);
        %TODO: Should I normalize this?  Check Hardoon's notes
        %samples(i,:) = s/norm(s);
    end  
end