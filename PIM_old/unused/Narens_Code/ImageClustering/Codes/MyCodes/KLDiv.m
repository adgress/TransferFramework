function [kl] = KLDiv(P, Q)
%This function assumes that the sum of the elements of P is 1.0. Also
%the sum of the elements of Q is also 1.0.

    n=length(P);
    kl=0;
    for i=1:n
        if (Q(i)==0)
            Q(i)=eps;
        end        
        if (P(i)==0)
           kl=kl+0; 
        else
            kl=kl+P(i)*log(P(i)/Q(i));
        end            
    end
    
    
end

