function [coolantT,qSolidCool] = march(T,H,inlet,massFlow,cp)
%MARCH March a quasi-steady coolant channel through its segments.
T=T(:); K=size(H,2); coolantT=zeros(K,1); prev=inlet; qSolidCool=zeros(K,1);
for k=1:K
    hk=H(:,k); coolantT(k)=(massFlow*cp*prev+sum(hk.*T))/max(massFlow*cp+sum(hk),eps);
    qSolidCool(k)=sum(hk.*(T-coolantT(k))); prev=coolantT(k);
end
end
