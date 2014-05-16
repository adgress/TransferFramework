function [memberships] = calculatemembershipProbs(data, meanproto, rhoByD)
    % U is a matrix that contains the soft assignments. This is w used in
    % some other functions.
    
s=size(data);
n=s(1,1);%number of data points
f=s(1,2);%number of features
k=size(meanproto,1); % number of clusters

memberships= zeros(n, k);

sums=zeros(1,n);
tops=zeros(n,k);
for i=1:n % for every data point
    for j=1:k % for every cluster
        %disp(sprintf('i=%d, j=%d', i, j))        
        %disp('data(i,:')
        %disp(data(i,:));
        %disp('meanproto(j,:)')
        %disp(meanproto(j,:));        
        %normSq=norm(data(i,:)-meanproto(j,:));
        sub=data(i,:)-meanproto(j,:);
        normSq=sub.*sub;
        %normSq=normSq*normSq;
        %disp('sub');
        %disp(sub);        
        sq=sum(normSq);
        %disp('sq');
        %disp(sq);
        %disp('rhoByD');
        %disp(rhoByD);        
        expPart=exp(-1.0*rhoByD*sq);
        if (expPart==0)
            expPart=eps;
        end
        %disp('sums(i): ');
        %disp(sums(i));
        %disp('expPart: ');
        %disp(expPart);    
        %digits(25);
        %sums(i) = vpa(sums(i));
        sums(i)=sums(i)+expPart;
        tops(i,j)=expPart;
%        disp(sprintf('i=%d, j=%d, sq=%f, rhoByD=%f, expPart=%f, sums(i)=%f', ...
%                      i,j, sq, rhoByD, expPart, sums(i)));

    end    
    if (sums(i)==0)
        disp(sprintf('i=%d, sums(i)=%f', i, sums(i)));
        disp('MeanProto:');
        disp(meanproto);
        err = MException('ResultChk:OutOfRange', ...
            'Resulting value is outside expected range');
        throw(err);
    end
end

for i=1:n % for every data point
    for j=1:k % for every cluster
        memberships(i,j)=tops(i,j)/sums(i);    
    end    
end

end