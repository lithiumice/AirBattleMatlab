function S = sodoku(M,S)        
if ~exist('S','var')   
    S = zeros([size(M),0]);   
end      

firstId = find(M(:)==0, 1 );  
if isempty(firstId)     
    S(:,:,size(S,3)+1) = M;  
else  
    [i,j] = ind2sub([9,9],firstId);      
    for k=1:9    
        ii = (ceil(i/3)-1)*3+1;          
        jj = (ceil(j/3)-1)*3+1;           
        mm = M(ii:ii+2,jj:jj+2);   
        if sum(M(i,:)==k)==0 && sum(M(:,j)==k)==0 && sum(mm(:)==k)==0   
            M(i,j) = k;  
            S = sodoku(M,S);            
        end
    end
end
% 
% M = [0,0,1,9,0,0,0,0,8;6,0,0,0,8,5,0,3,0;0,0,7,0,6,0,1,0,0;... 
% 0,3,4,0,9,0,0,0,0;0,0,0,5,0,4,0,0,0;0,0,0,0,1,0,4,2,0;...   
% 0,0,5,0,7,0,9,0,0;0,1,0,8,4,0,0,0,7;7,0,0,0,0,9,2,0,0];  
% S = sodoku(M)   