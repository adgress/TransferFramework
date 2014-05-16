function [a,b,c] = embedNewFormulation(data,options)   
    Kt_train = data.Kt_train;
    Km_train = data.Km_train;
    Kl_train = data.Kl_train;
    Wmt_train = data.Wmt_train;
    Wml_train = data.Wml_train;
    Wtl_train = data.Wtl_train;
    Wll_train = 1000*data.Wll_train;
    if options.centerData
        Km_train = (Km_train-repmat(mean(Km_train),size(Km_train,1),1));
        Kt_train = (Kt_train-repmat(mean(Kt_train),size(Kt_train,1),1));
        Kl_train = (Kl_train-repmat(mean(Kl_train),size(Kl_train,1),1));
    end
    [K_tm,C_tt] = computeK(Km_train,Kt_train,Wmt_train,options);
    [Q_mt] = computeQ(Km_train,Kt_train,Wmt_train,K_tm);
    Q = Q_mt;
    if options.locationConstraints
        if isfield(options,'constraintPercentage')
            display('');
        end
        C = computeC(Km_train,Wml_train,options);
        Q = Q + C;
    end   
    if options.includeLocations
        [K_lm,C_ll] = computeK(Km_train,Kl_train,Wml_train,options);
        [Q_ml] = computeQ(Km_train,Kl_train,Wml_train,K_lm);
        Q = Q + Q_ml;
    end
    if options.locationCannotLink
        Q_ll = computeIntraViewMatrix(Kl_train,K_lm,Wll_train,options);
        Q = Q + Q_ll;
    end
    D = diag(sum(Wmt_train,2));
    if options.includeLocations
        D = D + diag(sum(Wml_train,2));
    end    
    B = eye(size(Q_mt));
    if options.constraintMatrix == 2
        B = Km_train'*D*Km_train;
        Km_train_centered = (Km_train-repmat(mean(Km_train),size(Km_train,1),1));
        %B = Km_train_centered'*D*Km_train_centered;
        B = B + options.reg*eye(size(B));   
    end
    %Q = Q + options.reg*eye(size(Q));
    
    if options.justLocations
        Q = Kl_train'*Kl_train;
        B = eye(size(Q));
    end
    
    %[vec_images,vals_images] = eig(inv(B)*Q);
    [vec_images,vals_images] = eig(Q,B);
    [sortedVals,I] = sort(diag(vals_images),'ascend');        
    %sortedVals(1:5)
    discardTopEigenvector = 0;
    if discardTopEigenvector
        display('Discarding top eigenvector(s)');
        a = vec_images(:,I(2:end));
    else
        %display('Keeping first eigenvector');
        a = vec_images(:,I(1:end));
    end
    d = zeros(size(a,2),1);
    e = zeros(size(a,2),1);
    if options.normalizeVectors
        for i=1:size(a,2)
            ai = a(:,i);
            d(i) = sqrt(ai'*B*ai);
            ai = ai/d(i);
            a(:,i) = ai;   
            e(i) = norm(ai);
            if i==1
                %plot(ai);
                %find(abs(ai) > 1)
            end
        end    
    end
    [d(1:4) e(1:4) sortedVals(1:4)]
    if max(e) > 5
        display('');
    end
    if options.justLocations
        b = a;
        a = zeros(size(Km_train,1),100);
        c = zeros(size(Kt_train,1),100);
    else
        b = [];
        if options.includeLocations
            b = K_lm*a;
            justUseTop2LocationVecs = 0;
            if justUseTop2LocationVecs
                display('Just using top 2 location vectors');
                b = b(:,1:2);
            end
        end    
        c = K_tm*a;
    end
    
    %{
    v1 = diag(a'*a);
    v2 = diag(b'*b);
    v3 = diag(c'*c);
    Bloc = Kl_train'*diag(sum(Wml_train,1))*Kl_train;
    Bloc = Bloc + options.reg*eye(size(Bloc));
    Btag = Kt_train'*diag(sum(Wmt_train,1))*Kt_train;
    Btag = Btag + options.reg*eye(size(Btag));
    for i=1:size(b,2)
        bi = b(:,i);
        bi = bi/(bi'*Bloc*bi);
        b(:,i) = bi;
    end
    for i=1:size(c,2)
        ci = c(:,i);
        ci = ci/(ci'*Btag*ci);
        c(:,i) = ci;
    end
    plot(1:numel(v1),v1,'r',1:numel(v2),v2,'g',1:numel(v3),v3,'b');
    legend('Image Vecs','Location Vecs','Tag Vecs');
    %}
end

function [Q] = computeQ(K_view1,K_view2,W,K)
    Q = zeros(size(K_view1));
    for i=1:size(W,1)
        for j=1:size(W,2)
            if W(i,j) == 0
                continue;
            end
            xi = K_view1(i,:)';
            yj = K_view2(j,:)';
            p = xi - K'*yj;
            Q = Q + p*p';
        end
    end
end

function [C] = computeIntraViewMatrix(K_view,K_matrix,W,options)
    C = zeros(size(K_matrix,2));
    for i=1:size(W,1)
        for j=1:size(W,2)
            wij = W(i,j);
            if wij == 0
                continue;
            end
            xi = K_view(i,:)';
            xj = K_view(j,:)';
            p = K_matrix'*(xi-xj)*wij;
            C = C + p*p';
        end
    end
end

%(images,tags)
%(images,locs)

function [C] = computeC(K,W,options)
    C = zeros(size(K,2));
    for i=1:size(W,1)
        for j=1:size(W,2)
            if W(i,j) == 0
                continue;
            end
            xi = K(i,:);
            xj = K(j,:);
            p = xi-xj;
            C = C + p*p';
        end
    end
end

function [K,Cyy] = computeK(K_view1,K_view2,W,options)
    %This assumes Wmt_train(i,j) \in {0,1}
    Cyy = zeros(size(K_view2,2));
    Cyx = zeros(size(K_view2,2),size(K_view1,2));
    for i=1:size(W,1)
        for j=1:size(W,2)
            if W(i,j) == 0
                continue;
            end
            xi = K_view1(i,:)';
            yj = K_view2(j,:)';
            Cyy = Cyy + yj*yj';
            Cyx = Cyx + yj*xi';
        end
    end
    %%Should we regularize here?
    if options.reg == 0 || size(Cyy,1) == 2
        Cyy_inv = pinv(Cyy);
    else
        Cyy_inv = inv(Cyy+(options.reg)*eye(size(Cyy)));
    end
    K = Cyy_inv*Cyx;
end
