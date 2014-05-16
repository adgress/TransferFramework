function [theMemberships] = calculateSymMembershipProbs(data, meanproto, rhoByD)
    % U is a matrix that contains the soft assignments. This is w used in
    % some other functions.
    
s=size(data);
n=s(1,1);%number of data points
f=s(1,2);%number of features
k=size(meanproto,1); % number of clusters

memberships= zeros(n, k);
theMemberships=sym(memberships);
sums=zeros(1,n);
theSums=sym(sums);
tops=zeros(n,k);
theTops=sym(tops);
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
        %disp('theSums(i): ');
        %disp(theSums(i));
        %disp('expPart: ');
        %disp(expPart);    
        %digits(25);
        %sums(i) = vpa(sums(i));
        expPart=vpa(expPart);
        theSums(i)=theSums(i)+expPart;
        %disp('theSums: ');
        %disp(theSums);
        %sums(i)=sums(i)+expPart;
        theTops(i,j)=expPart;
%        disp(sprintf('i=%d, j=%d, sq=%f, rhoByD=%f, expPart=%f, sums(i)=%f', ...
%                      i,j, sq, rhoByD, expPart, sums(i)));

    end    
%     if (sums(i)==0)
%         disp(sprintf('i=%d, sums(i)=%f', i, sums(i)));
%         disp('MeanProto:');
%         disp(meanproto);
%         err = MException('ResultChk:OutOfRange', ...
%             'Resulting value is outside expected range');
%         throw(err);
%     end
end

for i=1:n % for every data point
    for j=1:k % for every cluster
        theMemberships(i,j)=theTops(i,j)/theSums(i);    
    end    
end

%disp('Size of theMemberships');
%disp(size(theMemberships));

end